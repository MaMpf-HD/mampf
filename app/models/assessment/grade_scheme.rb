module Assessment
  class GradeScheme < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment"
    belongs_to :applied_by, class_name: "User", optional: true

    PASSING_GRADES = [4.0, 3.7, 3.3, 3.0, 2.7, 2.3, 2.0, 1.7, 1.3, 1.0].freeze

    enum :kind, { banded: 0 }

    validates :config, presence: true
    validates :assessment_id, uniqueness: { conditions: -> { where(active: true) } },
                              if: :active?
    validates :points_step, numericality: { greater_than: 0 }
    validate :config_matches_kind
    validate :immutable_when_applied, on: :update
    validate :assessable_must_be_pointable_and_gradable

    before_save :compute_hash, if: :config_changed?

    def applied?
      applied_at.present?
    end

    def compute_hash
      self.version_hash = Digest::MD5.hexdigest(
        deep_sort_keys(config).to_json
      )
    end

    def self.two_point_auto(excellence:, passing:, max_points:, step: 1)
      raise(ArgumentError, "excellence must be > passing") unless excellence > passing
      raise(ArgumentError, "passing must be >= 0") if passing.negative?
      raise(ArgumentError, "excellence must be <= max_points") if excellence > max_points

      min_range = (PASSING_GRADES.size - 1) * step
      if (excellence - passing) < min_range
        raise(ArgumentError, "range too narrow: need at least #{min_range} points for step=#{step}")
      end

      raw_step = (excellence - passing).to_f / (PASSING_GRADES.size - 1)

      bands = PASSING_GRADES.each_with_index.map do |grade, i|
        raw = passing + (i * raw_step)
        min_pts = (raw / step).round * step
        { "min_points" => min_pts, "grade" => grade.to_s }
      end

      pts_values = bands.pluck("min_points")
      if pts_values.uniq.size < pts_values.size
        raise(ArgumentError, "range too narrow: grade boundaries collapse with step=#{step}")
      end

      bands.unshift({ "min_points" => 0, "grade" => "5.0" }) if passing.positive?

      { "bands" => bands }
    end

    private

      def immutable_when_applied
        return if applied_at_was.blank?

        protected_attrs = changed - ["active", "applied_at", "applied_by_id", "updated_at"]
        return if protected_attrs.empty?

        errors.add(:base, :immutable_when_applied)
      end

      def assessable_must_be_pointable_and_gradable
        return unless assessment&.assessable

        assessable = assessment.assessable
        return if assessable.is_a?(::Assessment::Pointable) &&
                  assessable.is_a?(::Assessment::Gradable)

        errors.add(:assessment, :must_be_pointable_and_gradable)
      end

      def config_matches_kind
        case kind.to_sym
        when :banded
          validate_banded_config
        end
      end

      def deep_sort_keys(obj)
        case obj
        when Hash
          obj.sort.to_h.transform_values { |v| deep_sort_keys(v) }
        when Array
          obj.map { |v| deep_sort_keys(v) }
        else
          obj
        end
      end

      # banded config schema:
      #   { "bands" => [{ "min_points" => 54, "grade" => "1.0" }, ...] }
      # or with percentages:
      #   { "bands" => [{ "min_pct" => 90, "max_pct" => 100, "grade" => "1.0" }, ...] }
      # All bands must use the same format (points xor percentages).
      def validate_banded_config
        return unless config.is_a?(Hash)

        bands = config["bands"]
        unless bands.is_a?(Array) && bands.any?
          errors.add(:config, "must have a non-empty bands array")
          return
        end

        first = bands.first
        has_points = first.key?("min_points")
        has_pct = first.key?("min_pct")

        unless has_points || has_pct
          errors.add(:config, "bands must use min_points or min_pct")
          return
        end

        key = has_points ? "min_points" : "min_pct"
        unless bands.all? { |b| b.key?(key) }
          errors.add(:config, "all bands must use the same format")
          return
        end

        return if bands.all? { |b| b["grade"].present? }

        errors.add(:config, "every band must have a grade")
      end
  end
end
