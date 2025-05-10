module Vignettes
  class Questionnaire < ApplicationRecord
    belongs_to :lecture
    has_many :slides,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire
    has_many :info_slides,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire
    has_many :user_answers,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy,
             inverse_of: :questionnaire

    def answers_data
      slides.includes(answers: [:options, :slide_statistic,
                                { user_answer: :user }]).flat_map(&:answers)
    end

    def answer_data_csv
      Vignettes::CsvHandler.generate_questionnaire_csv(self)
    end

    def last_slide
      return nil if slides.empty?

      slides.order(:position).last
    end
  end
end
