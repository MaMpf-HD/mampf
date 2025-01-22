module Vignettes
  class InfoSlide < ApplicationRecord
    has_and_belongs_to_many :slides,
                            class_name: "Vignettes::Slide",
                            join_table: "vignettes_info_slides_slides",
                            foreign_key: "vignettes_info_slide_id",
                            association_foreign_key: "vignettes_slide_id"

    has_rich_text :content
    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id", inverse_of: :info_slides
  end
end
