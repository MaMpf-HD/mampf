class SchemeFormComponent < ViewComponent::Base
  # Component for rendering the form to create or edit a grade scheme for an
  # assessment.

  def initialize(assessment:, grade_scheme:)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
  end

  attr_reader :assessment, :grade_scheme

  def form_url
    if grade_scheme.persisted?
      helpers.assessment_assessment_grade_scheme_path(
        assessment, grade_scheme
      )
    else
      helpers.assessment_assessment_grade_schemes_path(assessment)
    end
  end

  def form_method
    grade_scheme.persisted? ? :patch : :post
  end

  def max_points
    assessment.effective_total_points || 0
  end

  def student_points_json
    assessment.assessment_participations
              .where(status: :reviewed)
              .pluck(:points_total)
              .compact
              .map(&:to_f)
              .to_json
  end

  def default_excellence
    existing_excellence || (max_points * 0.9).round
  end

  def default_passing
    existing_passing || (max_points * 0.5).round
  end

  def existing_bands
    return [] unless grade_scheme.config.is_a?(Hash)

    grade_scheme.config["bands"] || []
  end

  def default_points_step
    grade_scheme.points_step || 1
  end

  def editing?
    grade_scheme.persisted?
  end

  def cancel_path
    assessable = assessment.assessable
    if assessable.is_a?(Exam)
      helpers.exam_path(assessable, tab: "grade_scheme")
    else
      helpers.assessment_assessment_path(
        assessment,
        assessable_type: assessable.class.name,
        assessable_id: assessable.id,
        tab: "grade_scheme"
      )
    end
  end

  private

    def existing_excellence
      return nil if existing_bands.empty?

      band10 = existing_bands.find { |b| b["grade"] == "1.0" }
      band10&.dig("min_points")
    end

    def existing_passing
      return nil if existing_bands.empty?

      band40 = existing_bands.find { |b| b["grade"] == "4.0" }
      band40&.dig("min_points")
    end
end
