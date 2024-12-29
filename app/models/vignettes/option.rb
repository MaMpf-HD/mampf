module Vignettes
  class Option < ApplicationRecord
    belongs_to :question, inverse_of: :options, foreign_key: "vignettes_question_id"
    validates :text, presence: true
  end
end
