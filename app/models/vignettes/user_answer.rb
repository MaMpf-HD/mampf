module Vignettes
  class UserAnswer < ApplicationRecord
    belongs_to :user
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_many :answers, class_name: "Vignettes::Answer", foreign_key: "vignettes_user_answer_id",
                       dependent: :destroy
  end
end
