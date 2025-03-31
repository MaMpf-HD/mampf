module Vignettes
  module QuestionnairesHelper
    def group_questionnaires_by_completion(questionnaires, user)
      completed = []
      incomplete = []

      questionnaires.each do |questionnaire|
        user_answer = user.vignettes_user_answers.find_by(questionnaire: questionnaire)
        is_completed = user_answer&.last_slide_answered?

        if is_completed
          completed << questionnaire
        else
          incomplete << questionnaire
        end
      end

      { completed: completed, incomplete: incomplete }
    end

    def sort_questionnaires_by_completion_status(questionnaires, user)
      questionnaires.sort_by do |questionnaire|
        user_answer = user.vignettes_user_answers.find_by(questionnaire: questionnaire)
        if user_answer&.last_slide_answered?
          2  # Completed questionnaires last
        elsif user_answer.present?
          0  # In-progress questionnaires in the middle
        else
          1  # Not-started questionnaires first
        end
      end
    end

    def format_question_text(text)
      return "" if text.blank?

      text = text.to_s.dup
      text.gsub!(/\*\*(.*?)\*\*/, '<strong>\1</strong>') # Bold
      text.gsub!(/\*([^\*]+)\*/, '<em>\1</em>') # Italic

      simple_format(text, {}, sanitize: false)
    end
  end
end
