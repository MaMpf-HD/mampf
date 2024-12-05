module Vignettes
  class Questionnaire < ApplicationRecord
    has_many :slides,
             foreign_key: "vignettes_questionnaire_id",
             dependent: :destroy
  end
end
