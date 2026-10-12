# Feedback from the muffin next to the support button. It is mailed to the
# team, not stored, and anonymous unless its author sets `can_contact`.
class Feedback
  include ActiveModel::Model
  include ActiveModel::Attributes

  BODY_MIN_LENGTH = 6
  BODY_MAX_LENGTH = 10_000

  attribute :body, :string
  attribute :can_contact, :boolean, default: false

  validates :body, presence: true,
                   length: { minimum: BODY_MIN_LENGTH, maximum: BODY_MAX_LENGTH,
                             allow_blank: true }
end
