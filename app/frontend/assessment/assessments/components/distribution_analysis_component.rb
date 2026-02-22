class DistributionAnalysisComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  BIN_COUNT = 10

  def initialize(assessment:)
    super()
    @assessment = assessment
  end

  attr_reader :assessment

  def distribution
    @distribution ||= begin
      scheme = assessment.grade_scheme || assessment.build_grade_scheme(kind: :banded)
      Assessment::GradeSchemeApplier.new(scheme).analyze_distribution
    end
  end

  def empty?
    distribution[:count].zero?
  end

  def bins
    @bins ||= build_bins
  end

  def max_bin_count
    bins.pluck(:count).max || 1
  end

  def stat_rows
    [
      [t("assessment.distribution.students_reviewed"),
       "#{distribution[:count]} / #{total_count}",
       true],
      [t("assessment.distribution.minimum"),
       format_points(distribution[:min])],
      [t("assessment.distribution.maximum"),
       format_points(distribution[:max])],
      [t("assessment.distribution.mean"),
       format_points(distribution[:mean]),
       true],
      [t("assessment.distribution.median"),
       format_points(distribution[:median])],
      [t("assessment.distribution.std_dev"),
       distribution[:std_dev]&.to_s || "–"]
    ]
  end

  def percentile_rows
    distribution[:percentiles].map do |pct, value|
      label = t("assessment.distribution.percentile_nth", n: pct)
      label += " (#{t("assessment.distribution.median")})" if pct == 50
      [label, format_points(value), pct == 50]
    end
  end

  private

    def total_count
      assessment.assessment_participations.count
    end

    def reviewed_points
      @reviewed_points ||= assessment.assessment_participations
                                     .where(status: :reviewed)
                                     .pluck(:points_total)
                                     .compact
    end

    def build_bins
      max_possible = distribution[:max_possible] || distribution[:max] || 100
      return [] if max_possible.nil? || max_possible.zero?

      bin_width = (max_possible.to_f / BIN_COUNT).ceil
      bins = Array.new(BIN_COUNT) do |i|
        low = i * bin_width
        high = ((i + 1) * bin_width) - 1
        high = max_possible if i == BIN_COUNT - 1
        { low: low, high: high, count: 0 }
      end

      reviewed_points.each do |pts|
        idx = [(pts / bin_width).to_i, BIN_COUNT - 1].min
        bins[idx][:count] += 1
      end

      bins
    end

    def format_points(value)
      return "–" if value.nil?

      if value == value.to_i
        "#{value.to_i} #{t("assessment.distribution.points")}"
      else
        "#{value} #{t("assessment.distribution.points")}"
      end
    end
end
