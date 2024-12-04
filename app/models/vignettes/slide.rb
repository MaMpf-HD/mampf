module Vignettes
  class Slide < ApplicationRecord
    belongs_to :questionnaire
    has_rich_text :content
  end
end
