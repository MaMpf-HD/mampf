module StudentPerformance
  # Duck-typed stand-in for a persisted Rule, used to evaluate hypothetical
  # rule changes without touching the database.
  PreviewRule = Struct.new(
    :min_percentage,
    :min_points_absolute,
    :required_achievements,
    keyword_init: true
  )
end
