class UserCleanerJob
  include Sidekiq::Worker

  def perform
    UserCleaner.new.handle_inactive_users!
  end
end
