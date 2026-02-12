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

  def participations
    @participations ||= assessment
                        .assessment_participations
                        .joins(:user)
                        .includes(:user, :tutorial, :grader)
                        .order(:tutorial_id, "users.name")
  end

  def any_participations?
    participations.any?
  end

  def grade_display(participation)
    return nil unless participation.grade_numeric

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
end
