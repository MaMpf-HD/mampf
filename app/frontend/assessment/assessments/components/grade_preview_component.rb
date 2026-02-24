class GradePreviewComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(assessment:, grade_scheme:)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
    @applier = Assessment::GradeSchemeApplier.new(grade_scheme)
  end

  attr_reader :assessment, :grade_scheme

  def preview_rows
    @preview_rows ||= build_preview_rows
  end

  def total_reviewed
    preview_rows.size
  end

  def pass_count
    preview_rows.count { |r| r[:proposed_grade] <= 4.0 }
  end

  def fail_count
    total_reviewed - pass_count
  end

  def absent_rows
    @absent_rows ||= build_absent_rows
  end

  def any_absent?
    absent_rows.any?
  end

  def pass_rate
    return 0.0 if total_reviewed.zero?

    (pass_count.to_f / total_reviewed * 100).round(1)
  end

  def show_tutorial_column?
    !assessment.assessable.is_a?(Talk)
  end

  def grade_changed?(row)
    row[:current_grade].present? &&
      row[:current_grade] != row[:proposed_grade]
  end

  def pct_scheme?
    bands = grade_scheme.config&.dig("bands") || []
    bands.first&.key?("min_pct") || false
  end

  def back_path
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

  def apply_path
    helpers.apply_assessment_assessment_grade_scheme_path(
      assessment, grade_scheme
    )
  end

  private

    def build_preview_rows
      participations = assessment
                       .assessment_participations
                       .where(status: :reviewed)
                       .joins(:user)
                       .includes(:user, :tutorial)
                       .order(:tutorial_id, "users.name")

      participations.map do |p|
        {
          name: p.user.name,
          tutorial: p.tutorial&.title,
          points: p.points_total,
          current_grade: p.grade_numeric,
          proposed_grade: compute_grade(p)
        }
      end
    end

    def compute_grade(participation)
      points = participation.points_total
      return 5.0 if points.nil?

      bands = grade_scheme.config["bands"]
      sorted = bands.sort_by { |b| -b["min_points"] }
      band = sorted.find { |b| points >= b["min_points"] }
      band ? band["grade"].to_f : 5.0
    end

    def build_absent_rows
      assessment
        .assessment_participations
        .where(status: :absent)
        .joins(:user)
        .includes(:user, :tutorial)
        .order(:tutorial_id, "users.name")
        .map do |p|
          {
            name: p.user.name,
            tutorial: p.tutorial&.title,
            current_grade: p.grade_numeric
          }
        end
    end
end
