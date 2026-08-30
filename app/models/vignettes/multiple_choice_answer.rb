module Vignettes
  class MultipleChoiceAnswer < Answer
    validate :options_belong_to_the_question

    private

      # option_ids comes straight off the wire, so it may name options of an
      # entirely different question.
      def options_belong_to_the_question
        errors.add(:options, :blank) if options.empty?
        return if options.all? { |option| option.vignettes_question_id == vignettes_question_id }

        errors.add(:options, :invalid)
      end
  end
end
