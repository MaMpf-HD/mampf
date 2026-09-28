module StudentPerformance
  # What a lecture asks of a student before they may sit its exam: a points
  # threshold, a set of required achievements, both, or neither - then every
  # student is proposed as eligible, and staff refuse the few by hand. One rule
  # is active per lecture; the earlier ones stay for the certifications that
  # cite them.
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
    before_validation :drop_zero_threshold
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

    # Whether points decide anything. Only then does the rule wait for the
    # lecture's list of sheets and tests: another sheet changes the points
    # reachable and, as a share, the points needed.
    def points_threshold?
      min_percentage.present? || min_points_absolute.present?
    end

    def rule_achievement_ids_set
      Set.new(rule_achievements.pluck(:achievement_id))
    end

    private

      # Stores a zero threshold as threshold_mode none, so that 0 %, 0 points
      # and "No point threshold" are the same rule and show as "No requirement".
      def drop_zero_threshold
        if threshold_mode_percentage? && min_percentage&.zero?
          self.min_percentage = nil
        elsif threshold_mode_absolute? && min_points_absolute&.zero?
          self.min_points_absolute = nil
        else
          return
        end

        self.threshold_mode = :none
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
