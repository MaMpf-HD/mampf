class GradeSchemeTabComponent < ViewComponent::Base
  # Component for displaying the grade scheme tab in the assessment view,
  # showing the current status and actions available for the grade scheme.

  def initialize(assessment:, grade_scheme: nil)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
  end

  attr_reader :assessment, :grade_scheme

  def show_form?
    grade_scheme.present?
  end

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

  def apply_scheme_path
    helpers.apply_assessment_assessment_grade_scheme_path(
      assessment, assessment.grade_scheme
    )
  end

  def discard_scheme_path
    helpers.assessment_assessment_grade_scheme_path(
      assessment, assessment.grade_scheme
    )
  end

  def reviewed_count
    assessment.assessment_participations.where(status: :reviewed).count
  end

  def ungraded_reviewed_count
    return 0 unless scheme_applied?

    assessment.assessment_participations
              .where(status: :reviewed, grade_numeric: nil)
              .count
  end

  def graded_count
    assessment.assessment_participations
              .where.not(grade_numeric: nil)
              .count
  end

  def draft_change_count
    return 0 unless scheme_exists? && !scheme_applied?

    Assessment::GradeSchemeApplier.new(assessment.grade_scheme).change_count
  end

  def pending_count
    assessment.assessment_participations.where(status: :pending).count
  end

  def absent_count
    assessment.assessment_participations.where(status: :absent).count
  end

  def exempt_count
    assessment.assessment_participations.where(status: :exempt).count
  end

  def total_count
    assessment.assessment_participations.count
  end
end
