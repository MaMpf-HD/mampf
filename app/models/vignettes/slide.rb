module Vignettes
  class Slide < ApplicationRecord
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id"
    has_rich_text :content
    has_one :question, dependent: :destroy, inverse_of: :slide
    has_many :answers, dependent: :destroy, inverse_of: :slide
    has_many :slide_statistics, through: :answers
    accepts_nested_attributes_for :question, allow_destroy: true

    has_and_belongs_to_many :info_slides, class_name: "Vignettes::InfoSlide",
                                          join_table: "vignettes_info_slides_slides"

    has_one :info_slide, class_name: "Vignettes::InfoSlide", foreign_key: "vignettes_slide_id",
                         dependent: :destroy
    validates :position, presence: true, numericality: { only_integer: true }
    validates :position, uniqueness: { scope: :vignettes_questionnaire_id }
  end
end
