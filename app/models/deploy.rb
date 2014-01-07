class Deploy < ActiveRecord::Base
  belongs_to :stage
  belongs_to :job

  delegate :started_by?, :stop!, :status, :user, :output, to: :job
  delegate :project, to: :stage

  def summary
    "#{job.user.name} #{summary_action} #{commit} to #{stage.name}"
  end

  def pending?
    status == "pending"
  end

  def running?
    status == "running"
  end

  def succeeded?
    status == "succeeded"
  end

  def cancelling?
    status == "cancelling"
  end

  def failed?
    status == "failed"
  end

  def self.active
    joins(:job).where(jobs: { status: %w[pending running] })
  end

  private

  def summary_action
    if pending?
      "is waiting to deploy"
    elsif running?
      "is deploying"
    elsif cancelling?
      "is cancelling a deploy of"
    elsif succeeded?
      "successfully deployed"
    elsif failed?
      "failed to deploy"
    end
  end
end
