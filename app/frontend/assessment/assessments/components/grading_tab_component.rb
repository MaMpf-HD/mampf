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
  # being drafted shows its proposal beside each one.
  def roster_component
    if assessment.assessable.is_a?(Exam)
      ExamGradingTableComponent.new(exam: assessment.assessable)
    else
      GradeTableComponent.new(assessment: assessment, draft_scheme: draft_scheme)
    end
  end

  private

    def draft_scheme
      scheme = assessment.grade_scheme
      return nil unless scheme&.persisted?
      return nil if scheme.applied?

      scheme
    end
end
