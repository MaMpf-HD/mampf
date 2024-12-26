module Vignettes
  class Question < ApplicationRecord
    # Uses single table inheritance to store different types of answers
    belongs_to :slide

    validates :question_text, presence: true

    self.abstract_class = false
  end
end
