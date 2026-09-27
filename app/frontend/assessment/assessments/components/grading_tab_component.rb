# Missing top-level docstring, please formulate one yourself 😁
class GradingTabComponent < ViewComponent::Base
  def initialize(assessment:, grade_scheme: nil)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
  end

  attr_reader :assessment, :grade_scheme

  def show_form?
    grade_scheme.present?
  end

  def full_width?
    false
  end

  def show_roster?
    !full_width?
  end

  def scheme_component
    GradeSchemeTabComponent.new(
      assessment: assessment,
      grade_scheme: grade_scheme
    )
  end

  def roster_component
    ExamGradingTableComponent.new(exam: assessment.assessable)
  end
end
