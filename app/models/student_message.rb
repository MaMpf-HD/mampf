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
  def address_to(audiences, labels: {})
    @addressed = audiences
    @labels = labels
  end

  # A message saved before the labels were kept in every language has only
  # the one it was sent in.
  def audience_labels
    audiences.map { |audience| audience.dig("labels", I18n.locale.to_s) || audience["label"] }
  end

  # Groups the saved addresses by their owner's language; an address no
  # account has any more gets the default.
  def recipient_emails_by_locale
    locales = User.where(email: recipient_emails).pluck(:email, :locale).to_h
    recipient_emails.group_by { |email| (locales[email].presence || I18n.default_locale).to_s }
  end

  # A row from before groups could be picked has no labels; the audit and
  # the footer share one fallback for it.
  def audience_sentence
    audience_labels.presence&.to_sentence ||
      I18n.t("student_message.everyone_registered_then")
  end

  # The sender's own copy and, on a staff message, the lecture staff's cc.
  def copy_emails
    staff = staff? ? [lecture.teacher, *lecture.editors].map(&:email) : []
    [sender.email, *staff].uniq
  end

  def attachment_filename
    attachment&.metadata&.fetch("filename", nil)
  end

  private

    # The addresses are saved with the message, so that a group changing
    # between the send and the delivery job cannot retarget it.
    def snapshot_audiences
      return if @addressed.blank?

      self.audiences = @addressed.map do |audience|
        { key: audience.key, label: audience.label, labels: @labels[audience.key] }.compact
      end
      self.recipient_emails = StudentMessages::Audience.recipients(@addressed).pluck(:email)
      self.recipients_count = recipient_emails.size
    end
end
