module Assessment
  # Writes what a tutor entered for somebody on an achievement: "pass" or
  # "fail" on a yes/no one, a number on a numeric one, a percentage on the
  # third. The row never becomes reviewed - a certificate handed in later has
  # to be able to excuse it, and `Achievement#met_by?` reads the value alone.
  class AchievementValueService
    class InvalidValueError < StandardError; end

    BOOLEAN_VALUES = [Achievement::PASSED, "fail"].freeze

    # The block sees the row as the lock read it: the group that holds the
    # row may have changed since the caller looked, and with it who may
    # enter for it.
    def self.enter(participation, value, grader)
      achievement = participation.assessment.assessable
      value = normalize(achievement, value.to_s.strip)

      participation.with_lock do
        yield(participation) if block_given?
        GradeEntryService.refuse_absent_or_exempt!(participation)
        stamp = if value.nil?
          { grader_id: nil, graded_at: nil }
        else
          { grader: grader, graded_at: Time.current }
        end
        participation.update!(grade_text: value, status: :pending, **stamp)
      end
      participation
    end

    # Blank clears the value; anything else has to be what the type can read.
    def self.normalize(achievement, value)
      return nil if value.blank?
      return value if achievement.boolean? && BOOLEAN_VALUES.include?(value)

      number = Achievement.numeric_value(value) unless achievement.boolean?
      return value.tr(",", ".") if number && number >= 0 && (achievement.numeric? || number <= 100)

      kind = I18n.t("assessment.achievements.value_types.#{achievement.value_type}")
      raise(InvalidValueError,
            I18n.t("assessment.achievements.marking.invalid_value", value: value, kind: kind))
    end
  end
end
