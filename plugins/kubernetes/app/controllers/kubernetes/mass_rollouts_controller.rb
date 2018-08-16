# frozen_string_literal: true
class Kubernetes::MassRolloutsController < ApplicationController
  before_action :authorize_super_admin!
  before_action :deploy_group

  def deploy
    stages_to_deploy = deploy_group.stages.select(&:kubernetes?)
    deploys = stages_to_deploy.map do |stage|
      next unless stage.last_successful_deploy

      deploy_service = DeployService.new(current_user)
      deploy_service.deploy(stage, reference: stage.last_successful_deploy.reference)
    end.compact

    if deploys.empty?
      flash[:error] = "There were no stages ready for deploy."
      redirect_to deploys_path
    else
      redirect_to deploys_path(ids: deploys.map(&:id))
    end
  end

  private

  def deploy_group
    @deploy_group ||= DeployGroup.find_by_param!(params[:deploy_group_id])
  end
end
