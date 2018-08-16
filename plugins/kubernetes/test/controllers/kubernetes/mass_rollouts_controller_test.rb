# frozen_string_literal: true
require_relative '../../test_helper'

SingleCov.covered!

describe Kubernetes::MassRolloutsController do

  let(:deploy_group) { deploy_groups(:pod1) }
  let(:project) { projects(:test) }


  before do
    Kubernetes::ClusterDeployGroup.any_instance.stubs(:validate_namespace_exists)

    deploy_group.stages.delete_all

    @non_k8s_stage = Stage.create!(name: 'Production VMs Pod100', project: project, deploy_groups: [deploy_group])
    @k8s_stage = Stage.create!(name: 'Production K8s Pod100', project: project, deploy_groups: [deploy_group], kubernetes: true)

    deploys(:succeeded_test).update(stage: @non_k8s_stage)
    deploys(:succeeded_test).update(stage: @k8s_stage)
  end

  as_a_project_admin do
    unauthorized :post, :deploy, deploy_group_id: 1
  end

  as_a_super_admin do
    describe "#deploy" do
      it "deploys all k8s stages for this deploy_group" do
        post :deploy, params: {deploy_group_id: deploy_group}

        deploy = @k8s_stage.deploys.order('created_at desc').first.id
        assert_nil flash[:error]
        assert_redirected_to "/deploys?ids%5B%5D=#{deploy}"
      end

      it 'ignores non k8s stages' do
        assert_no_difference '@non_k8s_stage.deploys.count' do
          post :deploy, params: {deploy_group_id: deploy_group}
        end
      end

      it 'ignores stages with no successful deployment' do
        @k8s_stage.deploys.delete_all
        deploys(:failed_staging_test).update(stage: @k8s_staget)

        assert_no_difference '@k8s_stage.deploys.count' do
          post :deploy, params: {deploy_group_id: deploy_group}
        end
        assert_match /no stages ready/, flash[:error]
      end

      it 'uses the last successful deployment reference to deploy' do
        post :deploy, params: {deploy_group_id: deploy_group}

        assert_equal 'staging', @k8s_stage.deploys.order('created_at desc').first.reference
      end
    end
  end
end
