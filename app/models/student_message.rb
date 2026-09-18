# A one-off email from lecture staff or a tutor to the students of the groups
# they picked, optionally with an attachment. Kept as a record so that the
# sender has an audit trail of what went to whom, and so that the delivery
# job can be enqueued with just a reference.
class StudentMessage < ApplicationRecord
  include StudentMessageUploader[:attachment]

  belongs_to :lecture
  belongs_to :sender, class_name: "User"

  # Staff messages are the lecture's business and listed on its page; a
  # tutor's go to their own group and are theirs alone.
  enum :sender_role, { staff: 0, tutor: 1 }

  validates :subject, presence: true, length: { maximum: 200 }
  validates :body, presence: true
  # safety net: a message must never be persisted without an audience (the
  # snapshot happens in a callback right before validation); messages from
  # before groups could be picked carry none and stay as they are
  validates :audiences, :recipient_emails, presence: true, on: :create

  before_validation :snapshot_audiences, on: :create

  scope :to_audience, ->(key) { where("audiences @> ?", [{ key: key }].to_json) }

  # The groups the message goes to, as StudentMessages::Audience objects the
  # catalog resolved; what is stored is their keys, labels and addresses.
  def address_to(audiences)
    @addressed = audiences
  end

  def audience_labels
    audiences.pluck("label")
  end

  # A row from before groups could be picked has no labels; the audit and
  # the footer share one fallback for it.
  def audience_sentence
    audience_labels.presence&.to_sentence ||
      I18n.t("student_message.everyone_registered_then")
  end

  def attachment_filename
    attachment&.metadata&.fetch("filename", nil)
  end

  private

    # The addresses are saved with the message, so that a group changing
    # between the send and the delivery job cannot retarget it.
    def snapshot_audiences
      return if @addressed.blank?

      self.audiences = @addressed.map { |audience| { key: audience.key, label: audience.label } }
      user_ids = @addressed.flat_map(&:user_ids).uniq
      self.recipient_emails = User.where(id: user_ids).pluck(:email)
      self.recipients_count = recipient_emails.size
    end
end
