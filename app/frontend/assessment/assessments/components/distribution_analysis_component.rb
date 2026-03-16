class DistributionAnalysisComponent < ViewComponent::Base
  # Component for analyzing and displaying the distribution of assessment scores.

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

  def axis_tick_items
    @axis_tick_items ||= build_axis_tick_items
  end

  def max_possible
    @max_possible ||=
      distribution[:max_possible] || distribution[:max] || 0
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
      mp = max_possible.zero? ? 100 : max_possible
      return [] if mp.zero?

      count = (mp / 4.0).round.clamp(10, 30)
      width = (mp.to_f / count).ceil

      bins = Array.new(count) do |i|
        low = i * width
        high = ((i + 1) * width) - 1
        high = mp if i == count - 1
        { low: low, high: high, count: 0 }
      end

      reviewed_points.each do |pts|
        idx = [(pts / width).to_i, count - 1].min
        bins[idx][:count] += 1
      end

      max_c = bins.pluck(:count).max || 1
      bins.each do |bin|
        pct = max_c.positive? ? (bin[:count].to_f / max_c * 100).round : 0
        bin[:height_pct] = pct
        bin[:min_height_px] = bin[:count].positive? ? 4 : 0
      end

      bins
    end

    def build_axis_tick_items
      max = max_possible
      return [{ value: 0, style: "left: 0;" }] if max.zero?

      raw_step = max / 6.0
      magnitude = 10**Math.log10(raw_step).floor
      step = (raw_step / magnitude).ceil * magnitude
      ticks = (0..max).step(step).to_a
      ticks << max unless ticks.last == max

      ticks.map { |tick| { value: tick, style: tick_style(tick, max) } }
    end

    def tick_style(tick, max)
      pct = max.positive? ? (tick.to_f / max * 100).clamp(0, 100) : 0
      if pct.zero?
        "left: 0;"
      elsif pct >= 100
        "right: 0; transform: none;"
      else
        "left: #{pct}%; transform: translateX(-50%);"
      end
    end

    def build_threshold_markers
      return [] unless grade_scheme&.config&.dig("bands")

      max = max_possible.zero? ? 100 : max_possible
      return [] if max.zero?

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
