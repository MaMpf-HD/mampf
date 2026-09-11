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
    achievement.met_by?(participation.grade_text)
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

    # An unreadable value is shown as the tutor typed it; turning it into a 0
    # would claim they entered something they did not.
    def format_numeric(value)
      number = Achievement.numeric_value(value)
      return value.to_s if number.nil?

      number.to_s("F").sub(/\.0+\z/, "").sub(/(\.\d*?)0+\z/, "\\1")
    end
end
