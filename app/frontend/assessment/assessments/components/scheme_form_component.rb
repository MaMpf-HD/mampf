class SchemeFormComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  GERMAN_GRADES = ["1.0", "1.3", "1.7", "2.0", "2.3", "2.7", "3.0", "3.3", "3.7", "4.0",
                   "5.0"].freeze

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
