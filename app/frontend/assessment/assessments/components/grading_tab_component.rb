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

  # The lecturer enters or overrules a grade in the exam's rows; a scheme
  # being drafted shows its proposal beside each one. Only an exam has this
  # tab: a talk is graded in the seminar's table.
  def roster_component
    ExamGradingTableComponent.new(exam: assessment.assessable)
  end
end
