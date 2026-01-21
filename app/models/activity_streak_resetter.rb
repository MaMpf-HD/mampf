class ActivityStreakResetter
  def reset
    Streak
      .where(last_activity: ...threshold)
      .update_all(value: 0) # rubocop:disable Rails/SkipsModelValidations
  end

  private

    def threshold
      Time.current.prev_week.beginning_of_week
    end
end
