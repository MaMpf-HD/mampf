module Vignettes
  class InfoSlide < ApplicationRecord
    ACCEPTED_CONTENT_TYPES = ["image/png", "image/jpeg"].freeze

    validates :title, presence: true,
                      length: { minimum: 1, maximum: 255 }
    validates :icon, content_type: ACCEPTED_CONTENT_TYPES,
                     size: { less_than: 2.megabytes }

    has_and_belongs_to_many :slides,
                            class_name: "Vignettes::Slide",
                            join_table: "vignettes_info_slides_slides",
                            foreign_key: "vignettes_info_slide_id",
                            association_foreign_key: "vignettes_slide_id"

    has_rich_text :content
    has_one_attached :icon do |attachable|
      attachable.variant(:thumb, resize_to_limit: [200, 200])
    end

    belongs_to :questionnaire, foreign_key: "vignettes_questionnaire_id",
                               inverse_of: :info_slides
  end
end
