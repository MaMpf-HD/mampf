module StudentPerformance
  # What a rule change would do to the current proposals, without saving
  # anything. A decision set by hand is never swept, so its row is reported
  # apart from the ones a re-evaluation would actually move.
  class RuleChangePreview
    Change = Struct.new(:record, :from, :to, keyword_init: true)

    def initialize(current_rule:, preview_rule:, records:, certifications: [])
      @current_evaluator = Evaluator.new(current_rule)
      @preview_evaluator = Evaluator.new(preview_rule)
      @records = records
      @manual_user_ids = certifications.select(&:manual?).to_set(&:user_id)
    end

    def changes
      @changes ||= comparisons.reject { |change| settled_by_hand?(change) }
    end

    def manual_conflicts
      @manual_conflicts ||= comparisons.select { |change| settled_by_hand?(change) }
    end

    def newly(status)
      changes.count { |change| change.to == status }
    end

    private

      def comparisons
        @comparisons ||= @records.filter_map do |record|
          from = @current_evaluator.evaluate(record).proposed_status
          to = @preview_evaluator.evaluate(record).proposed_status
          next if from == to

          Change.new(record: record, from: from, to: to)
        end
      end

      def settled_by_hand?(change)
        @manual_user_ids.include?(change.record.user_id)
      end
  end
end
