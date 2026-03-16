module Assessment
  class GradeScheme < ApplicationRecord
    belongs_to :assessment, class_name: "Assessment::Assessment"
    belongs_to :applied_by, class_name: "User", optional: true

    enum :kind, { banded: 0 }

    validates :config, presence: true
    validates :assessment_id, uniqueness: true, if: :active?
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

    private

      def immutable_when_applied
        return if applied_at_was.blank?

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
