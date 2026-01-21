class ActivityStreakResetter
  include Sidekiq::Worker

  def perform
    resetter = ActivityStreakResetter.new
    resetter.reset!
  end
end
