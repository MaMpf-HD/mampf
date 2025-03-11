module Vignettes
  class TextAnswer < Answer
    TEXT_MIN_LENGTH = 1
    TEXT_MAX_LENGTH = 5_000

    validates :text, length: { minimum: TEXT_MIN_LENGTH,
                               maximum: TEXT_MAX_LENGTH },
                     allow_blank: false
  end
end
