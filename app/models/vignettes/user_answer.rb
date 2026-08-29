module Vignettes
  class UserAnswer < ApplicationRecord
    belongs_to :codename, class_name: "Vignettes::Codename",
                          foreign_key: "vignettes_codename_id",
                          inverse_of: :user_answers
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_many :answers, class_name: "Vignettes::Answer",
                       foreign_key: "vignettes_user_answer_id",
                       dependent: :destroy
  end
end
