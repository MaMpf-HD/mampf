class ActivityStreakResetter
  include Sidekiq::Worker

  def reset
    resetter = ActivityStreakResetter.new
    resetter.reset!
  end
end
