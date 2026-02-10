class GradeTableComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def participations
    @participations ||= assessment
                        .assessment_participations
                        .joins(:user)
                        .includes(:user, :tutorial, :grader)
                        .order(:tutorial_id, "users.name")
  end

  def graded_participations
    @graded_participations ||= participations.where(status: :graded)
  end

  def any_graded?
    graded_participations.any?
  end

  def grade_display(participation)
    return nil unless participation.grade_numeric

    if participation.grade_text.present? && participation.grade_text != participation.grade_numeric.to_s
      "#{participation.grade_numeric} (#{participation.grade_text})"
    else
      participation.grade_numeric.to_s
    end
  end

  def grader_display(participation)
    participation.grader&.tutorial_name
  end

  def graded_at_display(participation)
    return nil unless participation.graded_at

    I18n.l(participation.graded_at, format: :short)
  end
end
