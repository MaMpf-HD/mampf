module Vignettes
  class TextAnswer < Answer
    validates :text, presence: true
  end
end
