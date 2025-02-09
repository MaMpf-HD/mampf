module Vignettes
  class Questionnaire < ApplicationRecord
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
  end
end
