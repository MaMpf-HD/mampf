require "csv"

module Vignettes
  class CsvHandler
    HEADERS = ["Answer ID",
               "Created At",
               "Codename",
               "Slide position",
               "Slide title",
               "Total time on slide",
               "Time on slide",
               "Time on info slide",
               "Info slide access count",
               "Info slide first access time",
               "Answer",
               "Selected Options",
               "Likert Scale Option"].freeze

    def self.answer_data(answer)
      data = [
        answer.id,
        answer.created_at.strftime("%Y-%m-%d"),
        Codename.user_codename(answer.user_answer.user, answer.user_answer.questionnaire.lecture),
        answer.slide.position,
        answer.slide.title,
        answer.slide_statistic.total_time_on_slide,
        answer.slide_statistic.time_on_slide,
        answer.slide_statistic.time_on_info_slides,
        answer.slide_statistic.info_slides_access_count,
        answer.slide_statistic.info_slides_first_access_time
      ]

      case answer.type
      when "Vignettes::TextAnswer", "Vignettes::NumberAnswer"
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
      CSV.generate(col_sep: ";", encoding: "UTF-8") do |csv|
        csv << HEADERS
        answer_data.each do |answer|
          csv << answer_data(answer)
        end
      end
    end
  end
end
