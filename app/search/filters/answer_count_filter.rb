# Filters media of type 'Question' by the number of answers.
#
# This filter only modifies the scope if the search is exclusively for 'Question'
# media and a specific answer count is provided. Otherwise, it returns the
# scope unmodified.
#
# It handles a special case where an input of '7' filters for questions with
# more than 6 answers.
module Search
  module Filters
    class AnswerCountFilter < BaseFilter
      def call
        count_param = params[:answers_count]
        types_param = params[:types]

        # Ignore the filter if no answer count was specified.
        return scope if count_param.blank? || count_param == "irrelevant"

        # Ignore this filter unless the user is
        # searching exclusively for media of type 'Question'.
        # If other types are selected, this filter should not apply.
        return scope unless types_param == ["Question"]

        count = count_param.to_i
        question_scope = scope.where(sort: "Question")

        # The value '7' from the dropdown means '> 6'.
        if count == 7
          question_scope.where("answers_count > ?", 6)
        else
          question_scope.where(answers_count: count)
        end
      end
    end
  end
end
