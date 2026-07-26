module StudentPerformance
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
    validate :threshold_matches_mode
    validate :at_least_one_criterion

    def rule_achievement_ids_set
      Set.new(rule_achievements.pluck(:achievement_id))
    end

    # Criteria that survive the current save — excludes associated records that
    # are built but marked for removal.
    def pending_rule_achievements
      rule_achievements.reject(&:marked_for_destruction?)
    end

    private

      # A rule that constrains nothing certifies every student, so it is never a
      # meaningful configuration: leaving exam eligibility switched off has the
      # same effect without silently producing certifications.
      def at_least_one_criterion
        return if min_percentage.present? || min_points_absolute.present?
        return if pending_rule_achievements.any?

        errors.add(:base, :no_criteria)
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
