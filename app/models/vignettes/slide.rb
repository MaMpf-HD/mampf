module Vignettes
  class Slide < ApplicationRecord
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_rich_text :content
    has_one :question, dependent: :destroy, inverse_of: :vignettes_slide
  end
end
