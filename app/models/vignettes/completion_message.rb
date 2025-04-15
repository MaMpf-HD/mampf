module Vignettes
  class CompletionMessage < ApplicationRecord
    belongs_to :lecture
    has_rich_text :content
  end
end
