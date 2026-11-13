module StudentPerformance
  # Duck-typed stand-in for a persisted Rule, used to evaluate hypothetical
  # rule changes without touching the database.
  PreviewRule = Struct.new(
    :min_percentage,
    :min_points_absolute,
    :min_tests_passed,
    :required_achievements,
    keyword_init: true
  ) do
    def points_threshold?
      min_percentage.present? || min_points_absolute.present?
    end

    def tests_criterion?
      min_tests_passed.present?
    end

    def waits_for_list?
      points_threshold? || tests_criterion?
    end
  end
end
