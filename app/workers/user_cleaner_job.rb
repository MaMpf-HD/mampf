# rubocop:disable Lint/UnreachableCode
class UserCleanerJob
  include Sidekiq::Worker

  sidekiq_options retry: false # job will be discarded if it fails

  def perform
    # 2025-11-26: Due to MaMpf being put behind a VPN, external users might
    # currently not be able to log in, in order to mark their accounts as active.
    # Therefore, we temporarily disable the user cleaning job until further
    # notice by returning early here.
    return

    # Only run this job in production, not for mampf-experimental or mampf-next.
    # Note that Rails.env.production? is not sufficient in this context
    # as both mampf-experimental and mampf-next also run in production mode.
    production_name = ENV.fetch("PRODUCTION_NAME", nil)
    return if production_name != "mampf" && production_name != "mampf-new"

    UserCleaner.new.handle_inactive_users!
  end
end
# rubocop:enable Lint/UnreachableCode
