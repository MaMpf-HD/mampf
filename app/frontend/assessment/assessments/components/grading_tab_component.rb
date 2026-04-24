# Missing top-level docstring, please formulate one yourself 😁
class GradingTabComponent < ViewComponent::Base
  def initialize(assessment:, grade_scheme: nil, preview_mode: false)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
    @preview_mode = preview_mode
  end

  attr_reader :assessment, :grade_scheme

  def preview_mode?
    @preview_mode && assessment.grade_scheme&.persisted?
  end

  def show_form?
    grade_scheme.present? && !preview_mode?
  end

  def full_width?
    show_form? || preview_mode?
  end

  def show_roster?
    !full_width?
  end

  def scheme_component
    GradeSchemeTabComponent.new(
      assessment: assessment,
      grade_scheme: grade_scheme,
      preview_mode: @preview_mode
    )
  end

  def roster_component
    GradeTableComponent.new(assessment: assessment)
  end
end
