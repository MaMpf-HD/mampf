class UserCleaner
  include Sidekiq::Worker

  def perform
    user_cleaner = UserCleaner.new()
    user_cleaner.clean!
  end
end