module UserRegistrations
  # Adds the human-readable lecture titles a student-performance policy asks
  # for to its config, so the student-facing summary can name them. Shared by
  # the live eligibility trace and the historical rejection trace.
  module StudentPerformanceDecoration
    STUDENT_PERFORMANCE_KIND = "student_performance".freeze

    module_function

    # Returns a copy of the policy config with a "lectures" title list added.
    # The original config is never mutated.
    def decorate_config(config)
      config = config.to_h.deep_dup
      titles = Lecture.where(id: Array(config["lecture_ids"])).map(&:title)
      config["lectures"] = titles.join(", ").presence

      config
    end
  end
end
