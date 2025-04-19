module Vignettes
  class CompletionMessage < ApplicationRecord
    belongs_to :lecture, touch: true
    has_rich_text :content
  end
end
