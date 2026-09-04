module StudentPerformance
  # What a rule change would do to the current proposals, without saving
  # anything. A decision set by hand is never swept, so it is left out of the
  # movement and reported separately where the new rule contradicts it.
  class RuleChangePreview
    Change = Struct.new(:record, :from, :to, keyword_init: true)
    Conflict = Struct.new(:record, :decision, :proposed, keyword_init: true)

    def initialize(current_rule:, preview_rule:, records:, certifications:)
      @current_evaluator = Evaluator.new(current_rule)
      @preview_evaluator = Evaluator.new(preview_rule)
      @records = records
      @manual_certifications = certifications.select(&:manual?)
                                             .index_by(&:user_id)
    end

    def changes
      @changes ||= comparisons.reject { |change| settled_by_hand?(change.record) }
    end

    def manual_conflicts
      @manual_conflicts ||= @records.filter_map do |record|
        certification = @manual_certifications[record.user_id]
        next unless certification

        proposed = @preview_evaluator.evaluate(record).proposed_status
        next unless certification.disagrees_with?(proposed)

        Conflict.new(record: record,
                     decision: certification.status.to_sym,
                     proposed: proposed)
      end
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

      def settled_by_hand?(record)
        @manual_certifications.key?(record.user_id)
      end
  end
end
