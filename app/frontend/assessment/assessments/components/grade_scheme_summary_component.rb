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

  def saved_counts
    @saved_counts ||= compute_saved_counts
  end

  def saved_count_for(band)
    saved_counts[band["grade"]] || 0
  end

  def comparing?
    return false if grade_scheme.applied?

    saved_counts.values.any?(&:positive?)
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
    return 0.0 if total_reviewed.zero?

    (pass_count.to_f / total_reviewed * 100).round(1)
  end

  def fail_rate
    return 0.0 if total_reviewed.zero?

    (fail_count.to_f / total_reviewed * 100).round(1)
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

  def saved_bar_width(band)
    return 0 if max_count.zero?

    (saved_count_for(band).to_f / max_count * 100).round
  end

  def bar_color(band)
    band["grade"].to_f <= 4.0 ? "#198754" : "#dc3545"
  end

  def failed?(band)
    band["grade"].to_f > 4.0
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

      sorted_desc = bands.sort_by { |b| -b["min_points"] }
      result = bands.each_with_object({}) { |b, h| h[b["grade"]] = 0 }

      reviewed_points.each do |pts|
        band = sorted_desc.find { |b| pts >= b["min_points"] }
        result[band["grade"]] += 1 if band
      end

      result
    end

    def compute_saved_counts
      result = bands.each_with_object({}) { |b, h| h[b["grade"]] = 0 }

      assessment.assessment_participations
                .where.not(grade_numeric: nil)
                .pluck(:grade_numeric)
                .each do |g|
        key = format("%.1f", g)
        result[key] += 1 if result.key?(key)
      end

      result
    end

    def max_count
      @max_count ||= begin
        proposed = bands.map { |b| count_for(b) }
        saved = bands.map { |b| saved_count_for(b) }
        (proposed + saved).max || 0
      end
    end
end
