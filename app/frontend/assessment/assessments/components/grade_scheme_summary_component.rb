class GradeSchemeSummaryComponent < ViewComponent::Base
  # Component for summarizing the grade scheme of an assessment, showing the
  # distribution of grades

  GRADE_BADGE_CLASS = {
    "1.0" => "bg-success-subtle text-success-emphasis",
    "1.3" => "bg-success-subtle text-success-emphasis",
    "1.7" => "bg-success-subtle text-success-emphasis",
    "2.0" => "bg-primary-subtle text-primary-emphasis",
    "2.3" => "bg-primary-subtle text-primary-emphasis",
    "2.7" => "bg-primary-subtle text-primary-emphasis",
    "3.0" => "bg-warning-subtle text-warning-emphasis",
    "3.3" => "bg-warning-subtle text-warning-emphasis",
    "3.7" => "bg-warning-subtle text-warning-emphasis",
    "4.0" => "bg-warning-subtle text-warning-emphasis",
    "5.0" => "bg-danger-subtle text-danger-emphasis"
  }.freeze

  def initialize(assessment:, grade_scheme:)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
  end

  attr_reader :assessment, :grade_scheme

  def pct_scheme?
    raw = grade_scheme.config&.dig("bands") || []
    raw.first&.key?("min_pct") || false
  end

  def bands
    @bands ||= begin
      raw = grade_scheme.config&.dig("bands") || []
      raw.sort_by { |b| b["grade"].to_f }
    end
  end

  def badge_class(grade)
    GRADE_BADGE_CLASS[grade] || "bg-secondary"
  end

  def student_counts
    @student_counts ||= compute_counts
  end

  def count_for(band)
    student_counts[band["grade"]] || 0
  end

  def applied_counts
    @applied_counts ||= apply_bands(applied_bands, reviewed_points)
  end

  def grade_change_summary
    @grade_change_summary ||= compute_grade_change_summary
  end

  def comparing?
    return false if grade_scheme.applied?

    previous_applied_scheme.present?
  end

  def previous_applied_scheme
    return @previous_applied_scheme if defined?(@previous_applied_scheme)

    @previous_applied_scheme = Assessment::GradeScheme
                               .where(assessment_id: assessment.id)
                               .where.not(applied_at: nil)
                               .where.not(id: grade_scheme.id)
                               .order(applied_at: :desc)
                               .first
  end

  def applied_bands
    @applied_bands ||= begin
      raw = previous_applied_scheme&.config&.dig("bands")
      raw = raw.presence || grade_scheme.config&.dig("bands") || []
      raw.sort_by { |b| b["grade"].to_f }
    end
  end

  def applied_pass_count
    applied_bands
      .select { |b| b["grade"].to_f <= 4.0 }
      .sum { |b| applied_counts[b["grade"]] || 0 }
  end

  def applied_fail_count
    total_reviewed - applied_pass_count
  end

  def applied_pass_rate
    pct_of(applied_pass_count, total_reviewed)
  end

  def applied_fail_rate
    pct_of(applied_fail_count, total_reviewed)
  end

  def total_reviewed
    reviewed_points.size
  end

  def pass_count
    bands
      .select { |b| b["grade"].to_f <= 4.0 }
      .sum { |b| count_for(b) }
  end

  def fail_count
    total_reviewed - pass_count
  end

  def pass_rate
    pct_of(pass_count, total_reviewed)
  end

  def fail_rate
    pct_of(fail_count, total_reviewed)
  end

  def absent_count
    @absent_count ||= assessment.assessment_participations
                                .where(status: :absent).count
  end

  def exempt_count
    @exempt_count ||= assessment.assessment_participations
                                .where(status: :exempt).count
  end

  def any_excluded?
    absent_count.positive? || exempt_count.positive?
  end

  def bar_width(band)
    return 0 if max_count.zero?

    (count_for(band).to_f / max_count * 100).round
  end

  def fail_boundary?(idx)
    idx.positive? &&
      bands[idx - 1]["grade"].to_f <= 4.0 &&
      bands[idx]["grade"].to_f > 4.0
  end

  private

    def reviewed_points
      @reviewed_points ||= assessment.assessment_participations
                                     .where(status: :reviewed)
                                     .pluck(:points_total)
                                     .compact
                                     .map(&:to_f)
    end

    def compute_counts
      return {} if pct_scheme?

      apply_bands(bands, reviewed_points)
    end

    def apply_bands(rows, points)
      sorted_desc = rows.sort_by { |b| -b["min_points"] }
      result = rows.each_with_object({}) { |b, h| h[b["grade"]] = 0 }

      points.each do |pts|
        band = sorted_desc.find { |b| pts >= b["min_points"] }
        result[band["grade"]] += 1 if band
      end

      result
    end

    def compute_grade_change_summary
      return blank_change_summary if pct_scheme? || reviewed_points.empty?

      old_desc = applied_bands.sort_by { |b| -b["min_points"] }
      new_desc = bands.sort_by { |b| -b["min_points"] }
      result = blank_change_summary

      reviewed_points.each do |pts|
        old_band = old_desc.find { |b| pts >= b["min_points"] }
        new_band = new_desc.find { |b| pts >= b["min_points"] }
        next unless old_band && new_band

        old_grade = old_band["grade"].to_f
        new_grade = new_band["grade"].to_f

        if new_grade < old_grade
          result[:better] += 1
        elsif new_grade > old_grade
          result[:worse] += 1
        else
          result[:unchanged] += 1
        end

        old_failed = old_grade > 4.0
        new_failed = new_grade > 4.0
        result[:newly_failing] += 1 if !old_failed && new_failed
        result[:newly_passing] += 1 if old_failed && !new_failed
      end

      result
    end

    def blank_change_summary
      { better: 0, worse: 0, unchanged: 0,
        newly_failing: 0, newly_passing: 0 }
    end

    def pct_of(numerator, denominator)
      return 0.0 if denominator.zero?

      (numerator.to_f / denominator * 100).round(1)
    end

    def max_count
      @max_count ||= begin
        proposed = bands.map { |b| count_for(b) }
        applied = applied_bands.map { |b| applied_counts[b["grade"]] || 0 }
        (proposed + applied).max || 0
      end
    end
end
