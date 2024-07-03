# Feedback from users regarding MaMpf itself.
class Feedback < ApplicationRecord
  belongs_to :user

  BODY_MIN_LENGTH = 10
  BODY_MAX_LENGTH = 10_000
  validates :feedback, length: { minimum: BODY_MIN_LENGTH,
                                 maximum: BODY_MAX_LENGTH },
                       allow_blank: false
end
