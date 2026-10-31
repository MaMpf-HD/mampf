# Feedback from the muffin next to the support button. It is mailed to the
# team along with its author's name and email address, but not stored.
class Feedback
  include ActiveModel::Model
  include ActiveModel::Attributes

  BODY_MIN_LENGTH = 6
  BODY_MAX_LENGTH = 10_000

  attribute :body, :string

  validates :body, presence: true,
                   length: { minimum: BODY_MIN_LENGTH, maximum: BODY_MAX_LENGTH,
                             allow_blank: true }
end
