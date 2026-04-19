class GradeTableComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def show_tutorial_column?
    !assessment.assessable.is_a?(Talk)
  end

  def show_points_column?
    assessable = assessment.assessable
    assessable.is_a?(::Assessment::Pointable) &&
      assessable.is_a?(::Assessment::Gradable)
  end

  def points_display(participation)
    return "\u2014" unless participation.points_total

    participation.points_total.to_s
  end

  def gradeable_participations
    @gradeable_participations ||= participations.where(status: [:pending, :reviewed])
  end

  def absent_participations
    @absent_participations ||= participations.where(status: :absent)
  end

  def exempt_participations
    @exempt_participations ||= participations.where(status: :exempt)
  end

  def any_gradeable?
    gradeable_participations.any?
  end

  def any_excluded?
    absent_participations.any? || exempt_participations.any?
  end

  def absent_grade_display(participation)
    if participation.grade_numeric
      participation.grade_numeric.to_s
    else
      "5.0"
    end
  end

  def grade_display(participation)
    return "\u2014" unless participation.grade_numeric

    text = participation.grade_text
    numeric = participation.grade_numeric
    if text.present? && text != numeric.to_s
      "#{numeric} (#{text})"
    else
      numeric.to_s
    end
  end

  def grader_display(participation)
    participation.grader&.tutorial_name
  end

  def graded_at_display(participation)
    return nil unless participation.graded_at

    I18n.l(participation.graded_at, format: :short)
  end

  def excluded_participations
    @excluded_participations ||=
      participations.where(status: [:absent, :exempt])
  end

  def status_label(participation)
    I18n.t("assessment.grade_table.#{participation.status}")
  end

  private

    def participations
      @participations ||= assessment
                          .assessment_participations
                          .joins(:user)
                          .includes(:user, :tutorial, :grader)
                          .order(:tutorial_id, "users.name")
    end
end
