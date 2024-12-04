module Vignettes
  class Questionnaire < ApplicationRecord
    has_many :slides, dependent: :destroy
  end
end
