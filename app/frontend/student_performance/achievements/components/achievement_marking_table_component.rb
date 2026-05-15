class AchievementMarkingTableComponent < ViewComponent::Base
  def initialize(achievement:)
    super()
    @achievement = achievement
  end

  attr_reader :achievement

  delegate :boolean?, :numeric?, :percentage?, :threshold,
           to: :achievement

  def any_participations?
    participations.any?
  end

  def value_display(participation)
    return "\u2014" if participation.grade_text.blank?

    case achievement.value_type
    when "numeric"
      return "#{participation.grade_text.to_i} / \u2014" if threshold.blank?

      "#{participation.grade_text.to_i} / #{threshold.to_i}"
    when "percentage"
      return "#{format_percentage(participation.grade_text.to_f)} / \u2014" if threshold.blank?

      "#{format_percentage(participation.grade_text.to_f)} / #{format_percentage(threshold)}"
    end
  end

  def met?(participation)
    return false if participation.grade_text.blank?
    return false if threshold.blank? && !boolean?

    case achievement.value_type
    when "boolean"
      participation.grade_text == "pass"
    when "numeric"
      participation.grade_text.to_i >= threshold
    when "percentage"
      participation.grade_text.to_f >= threshold
    end
  end

  def status_badge(participation)
    return :unmarked if threshold.blank? && !boolean?
    return :unmarked if participation.grade_text.blank?

    met?(participation) ? :met : :not_met
  end

  def participations
    @participations ||= assessment
                        .assessment_participations
                        .joins(:user)
                        .includes(:user)
                        .order("users.name")
  end

  def marked_count
    @marked_count ||= participations.count { |p| p.grade_text.present? }
  end

  def met_count
    @met_count ||= participations.count { |p| met?(p) == true }
  end

  private

    def assessment
      achievement.assessment
    end

    def format_percentage(value)
      "#{format("%.1f", value.to_f)}%"
    end
end
