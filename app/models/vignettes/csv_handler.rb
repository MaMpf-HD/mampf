require "csv"

module Vignettes
  class CsvHandler
    HEADERS = ["Answer ID", "User", "Slide position", "Time on slide", "Time on info slide",
               "Info slide access count", "Question Text", "Answer", "Selected Options", "Likert Scale Option"]

    def self.answer_data(answer)
      data = [
        answer.id,
        answer.user_answer.user.name_or_email,
        answer.slide.position,
        answer.slide_statistic.time_on_slide,
        answer.slide_statistic.time_on_info_slides,
        answer.slide_statistic.info_slides_access_count,
        answer.slide.question.question_text
      ]

      case answer.type
      when "Vignettes::TextAnswer"
        data << answer.text
      when "Vignettes::MultipleChoiceAnswer"
        selected_options = answer.options.map(&:text).join(", ")
        data << ""
        data << selected_options
      when "Vignettes::LikertScaleAnswer"
        data << ""
        data << ""
        data << answer.likert_scale_value
      end

      data
    end

    def self.generate_questionnaire_csv(questionnaire)
      answer_data = questionnaire.answers_data
      CSV.generate do |csv|
        csv << HEADERS
        answer_data.each do |answer|
          csv << answer_data(answer)
        end
      end
    end
  end
end
