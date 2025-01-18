module Vignettes
  class InfoSlide < ApplicationRecord
    has_and_belongs_to_many :slides, class_name: "Vignettes::Slide",
                                     join_table: "vignettes_info_slides_slides"
    has_rich_text :content

    has_one :questionnaire, through: :slide
  end
end
