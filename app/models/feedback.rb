# An answer to the temporary "What can we improve?" survey behind the muffin
# next to the support button. It is stored without any link to its author,
# so that people can speak their mind. Whoever wants to be asked about it
# ticks `can_contact`; only the mail to the team then names them.
class Feedback < ApplicationRecord
  BODY_MIN_LENGTH = 6
  BODY_MAX_LENGTH = 10_000

  attribute :can_contact, :boolean, default: false

  validates :body, presence: true,
                   length: { minimum: BODY_MIN_LENGTH, maximum: BODY_MAX_LENGTH,
                             allow_blank: true }
end
