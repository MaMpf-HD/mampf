class GradeSchemeTabComponent < ViewComponent::Base
  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def phase
    return :applied if scheme_applied?
    return :draft if scheme_exists?

    :no_scheme
  end

  def pending_participations?
    assessment.assessment_participations.exists?(status: :pending)
  end

  def scheme_exists?
    assessment.grade_scheme&.persisted?
  end

  def scheme_applied?
    assessment.grade_scheme&.applied?
  end

  def new_scheme_path
    helpers.new_assessment_assessment_grade_scheme_path(assessment)
  end

  def edit_scheme_path
    helpers.edit_assessment_assessment_grade_scheme_path(
      assessment, assessment.grade_scheme
    )
  end

  def preview_scheme_path
    helpers.preview_assessment_assessment_grade_scheme_path(
      assessment, assessment.grade_scheme
    )
  end

  def apply_scheme_path
    helpers.apply_assessment_assessment_grade_scheme_path(
      assessment, assessment.grade_scheme
    )
  end

  def reviewed_count
    assessment.assessment_participations.where(status: :reviewed).count
  end

  def pending_count
    assessment.assessment_participations.where(status: :pending).count
  end

  def total_count
    assessment.assessment_participations.count
  end
end
