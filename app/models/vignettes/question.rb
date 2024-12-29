module Vignettes
  class Question < ApplicationRecord
    # Uses single table inheritance to store different types of answers
    belongs_to :slide, inverse_of: :question, foreign_key: "vignettes_slide_id"
    has_many :options, dependent: :destroy, inverse_of: :question

    accepts_nested_attributes_for :options, allow_destroy: true, reject_if: :all_blank

    validates :question_text, presence: true

    self.abstract_class = false
  end
end
