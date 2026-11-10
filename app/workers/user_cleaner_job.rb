class UserCleanerJob
  include Sidekiq::Worker

  sidekiq_options retry: false # job will be discarded if it fails

  def perform
    # Only run this job in production, not for mampf-experimental or mampf-next.
    # Note that Rails.env.production? is not sufficient in this context
    # as both mampf-experimental and mampf-next also run in production mode.
    instance_name = ENV.fetch("INSTANCE_NAME", nil)
    return unless instance_name == "mampf"

    UserCleaner.new.handle_inactive_users!
  end
end
