module Vignettes
  class Codename < ApplicationRecord
    MIN_LENGTH = 1
    MAX_LENGTH = 16

    validates :pseudonym, length: { minimum: MIN_LENGTH,
                                    maximum: MAX_LENGTH },
                          allow_blank: false

    belongs_to :user
    belongs_to :lecture
  end
end
