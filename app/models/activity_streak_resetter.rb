class ActivityStreakResetter
  def reset
    threshold = Time.zone.now.prev_week.prev_week.beginning_of_week
    User.where(last_activity: (..threshold)).update_all(activity_streak: 0) # rubocop:disable Rails/SkipsModelValidations -- update is guaranteed to pass validations
  end
end
