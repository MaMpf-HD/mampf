# A message to the MaMpf team from the support button. It is sent by mail and
# not stored; the answer goes to the address of the account it came from.
class SupportRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  MESSAGE_MIN_LENGTH = 10
  MESSAGE_MAX_LENGTH = 10_000

  attribute :message, :string
  attr_accessor :user

  validates :message, presence: true,
                      length: { minimum: MESSAGE_MIN_LENGTH, maximum: MESSAGE_MAX_LENGTH,
                                allow_blank: true }
end
