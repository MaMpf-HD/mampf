module Assessment
  class GradeSchemeApplier
    def initialize(scheme)
      @scheme = scheme
      @assessment = scheme.assessment
    end

    def analyze_distribution
      points = reviewed_participations.pluck(:points_total).compact
      return empty_distribution if points.empty?

      sorted = points.sort
      mean = sorted.sum.to_f / sorted.size

      {
        count: sorted.size,
        min: sorted.first,
        max: sorted.last,
        mean: mean.round(2),
        median: median(sorted),
        std_dev: std_dev(sorted, mean),
        percentiles: calculate_percentiles(sorted),
        max_possible: @assessment.effective_total_points
      }
    end

    def preview
      reviewed_participations.map do |p|
        {
          user_id: p.user_id,
          points: p.points_total,
          current_grade: p.grade_numeric,
          proposed_grade: compute_grade_for(p)
        }
      end
    end

    # On first apply, grades all reviewed participations. On re-apply
    # (same config), only grades participations with no grade yet. This
    # picks up late-reviewed students while preserving manual corrections.
    def apply!(applied_by:)
      target = if already_applied?
        ungraded_reviewed_participations
      else
        reviewed_participations
      end

      absent_target = if already_applied?
        ungraded_absent_participations
      else
        absent_participations
      end

      target_count = target.count
      absent_count = absent_target.count
      return 0 if already_applied? && target_count.zero? && absent_count.zero?

      now = Time.current

      Participation.transaction do
        target.find_each do |participation|
          grade = compute_grade_for(participation)
          participation.update!(
            grade_numeric: grade,
            grader: applied_by,
            graded_at: now
          )
        end

        absent_target.find_each do |participation|
          participation.update!(
            grade_numeric: 5.0,
            grader: applied_by,
            graded_at: now
          )
        end

        unless already_applied?
          @scheme.update!(
            applied_at: now,
            applied_by: applied_by
          )
        end
      end

      target_count + absent_count
    end

    def compute_grade_for(participation)
      points = participation.points_total
      return 5.0 if points.nil?

      bands = @scheme.config["bands"]
      first_band = bands.first

      if first_band.key?("min_points")
        apply_absolute_scheme(points, bands)
      elsif first_band.key?("min_pct")
        max = @assessment.effective_total_points
        return 5.0 if max.nil? || max.zero?

        pct = (points.to_f / max * 100).round(2)
        apply_percentage_scheme(pct, bands)
      else
        5.0
      end
    end

    private

      def reviewed_participations
        @assessment.assessment_participations.where(status: :reviewed)
      end

      def ungraded_reviewed_participations
        reviewed_participations.where(grade_numeric: nil)
      end

      def absent_participations
        @assessment.assessment_participations.where(status: :absent)
      end

      def ungraded_absent_participations
        absent_participations.where(grade_numeric: nil)
      end

      def already_applied?
        @scheme.applied?
      end

      def apply_absolute_scheme(points, bands)
        sorted = bands.sort_by { |b| -b["min_points"] }
        band = sorted.find { |b| points >= b["min_points"] }
        band ? band["grade"].to_f : 5.0
      end

      def apply_percentage_scheme(pct, bands)
        sorted = bands.sort_by { |b| -b["min_pct"] }
        band = sorted.find { |b| pct >= b["min_pct"] }
        band ? band["grade"].to_f : 5.0
      end

      def median(sorted)
        mid = sorted.size / 2
        if sorted.size.odd?
          sorted[mid]
        else
          ((sorted[mid - 1] + sorted[mid]) / 2.0).round(2)
        end
      end

      def std_dev(sorted, mean)
        return 0.0 if sorted.size < 2

        variance = sorted.sum { |x| (x - mean)**2 } / (sorted.size - 1).to_f
        Math.sqrt(variance).round(2)
      end

      def calculate_percentiles(sorted)
        {
          10 => percentile_at(sorted, 0.1),
          25 => percentile_at(sorted, 0.25),
          50 => percentile_at(sorted, 0.5),
          75 => percentile_at(sorted, 0.75),
          90 => percentile_at(sorted, 0.9)
        }
      end

      def percentile_at(sorted, fraction)
        idx = (sorted.size * fraction).ceil - 1
        idx = 0 if idx.negative?
        sorted[idx]
      end

      def empty_distribution
        {
          count: 0,
          min: nil,
          max: nil,
          mean: nil,
          median: nil,
          std_dev: nil,
          percentiles: {},
          max_possible: @assessment.effective_total_points
        }
      end
  end
end
