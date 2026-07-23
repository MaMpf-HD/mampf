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
      return "#{format_numeric(participation.grade_text)} / \u2014" if threshold.blank?

      "#{format_numeric(participation.grade_text)} / #{format_numeric(threshold)}"
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
      numeric_value(participation.grade_text) >= threshold
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

    def format_numeric(value)
      numeric_value(value).to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
    end

    def numeric_value(value)
      BigDecimal(value.to_s)
    rescue ArgumentError
      BigDecimal("0")
    end
end
