module StudentPerformance
  # What a lecture asks of a student before they may sit its exam: a points
  # threshold, a number of passed tests, a set of required achievements, any
  # of them together, or nothing. With nothing, every student is proposed as
  # eligible and staff refuse single students by hand. Only a test with a
  # passing threshold can be passed, so only those are counted. One rule is
  # active per lecture; the earlier ones stay for the certifications that cite
  # them.
  class Rule < ApplicationRecord
    belongs_to :lecture

    has_many :rule_achievements,
             class_name: "StudentPerformance::RuleAchievement",
             dependent: :destroy,
             autosave: true
    has_many :required_achievements,
             through: :rule_achievements,
             source: :achievement

    # `none` would collide with ActiveRecord's own `none` scope, hence the prefix.
    enum :threshold_mode, { percentage: 0, absolute: 1, none: 2 },
         prefix: true, default: :none

    validates :min_percentage,
              numericality: { greater_than_or_equal_to: 0,
                              less_than_or_equal_to: 100 },
              allow_nil: true
    validates :min_points_absolute,
              numericality: { greater_than_or_equal_to: 0 },
              allow_nil: true
    validates :min_tests_passed,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
    before_validation :drop_zero_threshold
    before_validation :drop_zero_tests
    validate :threshold_matches_mode

    # What this rule asks of one student, in points, out of the maximum it is
    # weighed against. A percentage only becomes a number once there are points
    # to take it of, and which points those are is the caller's question: the
    # mark in the standing bar is drawn against what is due so far, while "can
    # this still be reached" is a question about the whole term. It stays nil
    # where there are no points to weigh, because a threshold without a scale is
    # not a threshold.
    def required_points(max)
      case threshold_mode
      when "percentage"
        (min_percentage * max / 100).round(2) if max&.positive?
      when "absolute"
        min_points_absolute
      end
    end

    # Whether points decide anything: another sheet changes the points
    # reachable and, as a share, the points needed.
    def points_threshold?
      min_percentage.present? || min_points_absolute.present?
    end

    def tests_criterion?
      min_tests_passed.present?
    end

    def more_tests_than?(pass_fail_count)
      tests_criterion? && min_tests_passed > pass_fail_count
    end

    # Whether a verdict has to wait until the lecture calls its list of sheets
    # and tests complete: another sheet moves the points, another test is
    # another chance to pass one.
    def waits_for_list?
      points_threshold? || tests_criterion?
    end

    # Whether the rule asks for nothing, so that every student is proposed as
    # eligible.
    def no_requirement?
      !points_threshold? && !tests_criterion? && required_achievements.none?
    end

    def rule_achievement_ids_set
      Set.new(rule_achievements.pluck(:achievement_id))
    end

    private

      # Stores a zero threshold as threshold_mode none, so that 0 %, 0 points
      # and "No point threshold" are the same rule and show as "No requirement".
      def drop_zero_threshold
        if threshold_mode_percentage? && typed_zero?(:min_percentage)
          self.min_percentage = nil
        elsif threshold_mode_absolute? && typed_zero?(:min_points_absolute)
          self.min_points_absolute = nil
        else
          return
        end

        self.threshold_mode = :none
      end

      # Stores "0 tests" as no criterion, as a zero threshold is stored.
      def drop_zero_tests
        self.min_tests_passed = nil if typed_zero?(:min_tests_passed)
      end

      # Whether a zero was given. The cast value cannot say: Rails casts text
      # to 0 as well, and for a whole number a fraction too. Those are for the
      # validation to refuse, not for a requirement to vanish over.
      def typed_zero?(attribute)
        typed = public_send(:"#{attribute}_before_type_cast").to_s
        Float(typed, exception: false)&.zero? || false
      end

      # The mode is the single source of truth; the two value columns have to
      # agree with it, so a rule can never claim a threshold it does not carry.
      def threshold_matches_mode
        if min_percentage.present? && min_points_absolute.present?
          return errors.add(:base, :percentage_and_absolute_exclusive)
        end

        case threshold_mode
        when "percentage"
          errors.add(:min_percentage, :blank) if min_percentage.nil?
          errors.add(:min_points_absolute, :present) if min_points_absolute.present?
        when "absolute"
          errors.add(:min_points_absolute, :blank) if min_points_absolute.nil?
          errors.add(:min_percentage, :present) if min_percentage.present?
        when "none"
          errors.add(:base, :threshold_without_mode) if min_percentage.present? ||
                                                        min_points_absolute.present?
        end
      end
  end
end
