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

    # sorts questionnaire by completion status and title
    # the title is sorted alphanumerical where numbers have a higher priority then letters
    def sort_questionnaires_by_completion_status(questionnaires, user)
      questionnaires.sort_by do |questionnaire|
        user_answer = user.vignettes_user_answers.find_by(questionnaire: questionnaire)
        in_progress = user_answer.present? ? 0 : 1
        title_key = questionnaire.title.downcase.chars.map do |c|
          if /\d/.match?(c)
            c.to_i
          else
            c.ord + 10
          end
        end

        [in_progress, title_key]
      end
    end

    def all_questionnaires_completed?(user, questionnaires)
      published_questionnaires = questionnaires.where(published: true)

      return false if published_questionnaires.empty?

      published_questionnaires.all? do |questionnaire|
        user_answer = user.vignettes_user_answers.find_by(questionnaire: questionnaire)
        user_answer&.last_slide_answered?
      end
    end

    def user_has_codename?(user, lecture)
      Vignettes::Codename.find_by(user: user, lecture: lecture).present?
    end

    def user_codename(user, lecture)
      Vignettes::Codename.find_by(user: user, lecture: lecture)&.pseudonym
    end

    def user_started_questionnaire?(user, questionnaire)
      user.vignettes_user_answers.find_by(questionnaire: questionnaire).present?
    end

    def questionnaire_take_text(user, questionnaire)
      if user_started_questionnaire?(user, questionnaire)
        t("vignettes.continue")
      else
        t("vignettes.take")
      end
    end

    def format_question_text(text)
      return "" if text.blank?

      text = text.to_s.dup
      text.gsub!(/\*\*(.*?)\*\*/, '<strong>\1</strong>') # Bold
      text.gsub!(/\*([^*]+)\*/, '<em>\1</em>') # Italic

      simple_format(text, {}, sanitize: false)
    end
  end
end
