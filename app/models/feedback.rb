# An answer to the temporary "What can we improve?" survey behind the muffin
# next to the support button. It is stored without any link to its author,
# so that people can speak their mind.
class Feedback < ApplicationRecord
  BODY_MIN_LENGTH = 6
  BODY_MAX_LENGTH = 10_000

  validates :body, presence: true,
                   length: { minimum: BODY_MIN_LENGTH, maximum: BODY_MAX_LENGTH,
                             allow_blank: true }
end
