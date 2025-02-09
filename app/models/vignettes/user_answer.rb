module Vignettes
  class UserAnswer < ApplicationRecord
    belongs_to :user
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_many :answers, class_name: "Vignettes::Answer",
                       foreign_key: "vignettes_user_answer_id",
                       dependent: :destroy

    def answered_slide_ids
      answers.pluck(:vignettes_slide_id).uniq
    end

    def last_slide_answered?
      answered_slide_ids.include?(questionnaire.slides.order(:position).last.id)
    end

    def first_unanswered_slide
      questionnaire.slides.order(:position).find do |slide|
        answered_slide_ids.exclude?(slide.id)
      end
    end
  end
end
