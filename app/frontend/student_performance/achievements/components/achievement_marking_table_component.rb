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
    when "boolean"
      participation.grade_text == "pass" ? icon_pass : icon_fail
    when "numeric"
      "#{participation.grade_text.to_i} / #{threshold.to_i}"
    when "percentage"
      "#{format_percentage(participation.grade_text.to_f)} / #{format_percentage(threshold)}"
    end
  end

  def met?(participation)
    return false if participation.grade_text.blank?

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
    @marked_count ||= participations.where.not(grade_text: nil).count
  end

  def met_count
    @met_count ||= participations.count { |p| met?(p) == true }
  end

  private

    def assessment
      achievement.assessment
    end

    def icon_pass
      helpers.tag.i(class: "bi bi-check-circle-fill text-success")
    end

    def icon_fail
      helpers.tag.i(class: "bi bi-x-circle-fill text-danger")
    end

    def format_percentage(value)
      "#{value.to_f.truncate(1)}%"
    end
end
