# A message to the MaMpf team from the support button. It is sent by mail and
# not stored; somebody who is not signed in leaves an address to answer to.
class SupportRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  MESSAGE_MIN_LENGTH = 10
  MESSAGE_MAX_LENGTH = 10_000

  attribute :message, :string
  attribute :email, :string
  attribute :page, :string
  attr_accessor :user

  validates :message, length: { minimum: MESSAGE_MIN_LENGTH, maximum: MESSAGE_MAX_LENGTH }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                    unless: :user

  def reply_to
    user&.email || email
  end
end
