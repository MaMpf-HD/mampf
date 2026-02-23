class DistributionAnalysisComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  BIN_COUNT = 10

  def initialize(assessment:, grade_scheme: nil)
    super()
    @assessment = assessment
    @grade_scheme = grade_scheme
  end

  attr_reader :assessment, :grade_scheme

  def threshold_markers
    @threshold_markers ||= build_threshold_markers
  end

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

      bin_count = [[10, (max_possible / 4.0).round].max, 30].min
      bin_width = (max_possible.to_f / bin_count).ceil
      bins = Array.new(bin_count) do |i|
        low = i * bin_width
        high = ((i + 1) * bin_width) - 1
        high = max_possible if i == bin_count - 1
        { low: low, high: high, count: 0 }
      end

      reviewed_points.each do |pts|
        idx = [(pts / bin_width).to_i, bin_count - 1].min
        bins[idx][:count] += 1
      end

      bins
    end

    def axis_ticks
      max = distribution[:max_possible] || distribution[:max] || 0
      return [0] if max.zero?

      raw_step = max / 6.0
      magnitude = 10**Math.log10(raw_step).floor
      step = (raw_step / magnitude).ceil * magnitude
      ticks = (0..max).step(step).to_a
      ticks << max unless ticks.last == max
      ticks
    end

    def build_threshold_markers
      return [] unless grade_scheme&.config&.dig("bands")

      max = distribution[:max_possible] || distribution[:max] || 100
      return [] if max.nil? || max.zero?

      bands = grade_scheme.config["bands"]
      markers = []

      passing = bands.find { |b| b["grade"] == "4.0" }
      if passing
        pct = (passing["min_points"].to_f / max * 100).clamp(0, 100)
        markers << { label: "4.0", points: passing["min_points"], pct: pct,
                     color: "#dc3545" }
      end

      excellence = bands.find { |b| b["grade"] == "1.0" }
      if excellence
        pct = (excellence["min_points"].to_f / max * 100).clamp(0, 100)
        markers << { label: "1.0", points: excellence["min_points"], pct: pct,
                     color: "#198754" }
      end

      markers
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
