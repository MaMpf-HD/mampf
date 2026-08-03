module StudentPerformance
  # What a rule change would do to the current proposals, without saving
  # anything. Two screens ask this — the rule form and the what-if view — and
  # they differ only in where the hypothetical rule comes from, not in how the
  # comparison is drawn.
  class RuleChangePreview
    Change = Struct.new(:record, :from, :to, keyword_init: true)

    def initialize(current_rule:, preview_rule:, records:)
      @current_evaluator = Evaluator.new(current_rule)
      @preview_evaluator = Evaluator.new(preview_rule)
      @records = records
    end

    def changes
      @changes ||= @records.filter_map do |record|
        from = @current_evaluator.evaluate(record).proposed_status
        to = @preview_evaluator.evaluate(record).proposed_status
        next if from == to

        Change.new(record: record, from: from, to: to)
      end
    end

    def newly(status)
      changes.count { |change| change.to == status }
    end
  end
end
