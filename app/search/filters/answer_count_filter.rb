# Filters media of type 'Question' by the number of answers.
#
# This filter will only apply its logic if the search
# parameters explicitly request it for 'Question' media.
#
# It handles a special case where an input of '7' filters for questions with
# more than 6 answers.
module Search
  module Filters
    class AnswerCountFilter < BaseFilter
      def call
        # This filter is skipped unless the search is exclusively for Questions
        # AND a relevant answer count is provided. This check is based on the
        # original params, making it independent of filter order.
        return scope if skip_filter?

        count = params[:answers_count].to_i

        if count >= 7
          scope.where("answers_count > ?", 6)
        else
          scope.where(answers_count: count)
        end
      end

      private

        # Defines the specific skip conditions for this filter.
        def skip_filter?
          count_param = params[:answers_count]
          return true if count_param.blank? || count_param == "irrelevant"

          # This filter should only ever run if the search is exclusively for Questions.
          return true unless params[:types] == ["Question"]

          false
        end
    end
  end
end
