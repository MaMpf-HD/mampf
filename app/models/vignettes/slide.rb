module Vignettes
  class Slide < ApplicationRecord
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_rich_text :content
    has_one :question, dependent: :destroy, inverse_of: :slide
    has_many :answers, dependent: :destroy, inverse_of: :slide
    has_many :slide_statistics, through: :answers
    accepts_nested_attributes_for :question, allow_destroy: true
    validates :position, presence: true, numericality: { only_integer: true }
    validates :position, uniqueness: { scope: :vignettes_questionnaire_id }
  end
end
