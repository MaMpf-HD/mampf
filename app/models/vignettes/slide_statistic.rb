module Vignettes
  class SlideStatistic < ApplicationRecord
    validate :user_id, presence: true
    validate :vignettes_answer_id, presence: true

    belongs_to :user
    belongs_to :answer, class_name: "Vignettes::Answer", foreign_key: "vignettes_answer_id",
                        inverse_of: :slide_statistic
  end
end
