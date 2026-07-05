module Registration
  # A one-off email from the lecture staff to all students who registered
  # for the lecture (or are on its roster), optionally with an attachment
  # (e.g. a course program). Kept as a record so that teachers have an
  # audit trail of what was sent when, and so that the delivery job can
  # be enqueued with just a reference.
  #
  # Note: this is deliberately minimal (no group targeting, one
  # attachment, plain text) — a finer-grained mailing system is a planned
  # future extension.
  class StudentMessage < ApplicationRecord
    include StudentMessageUploader[:attachment]

    belongs_to :lecture
    belongs_to :sender, class_name: "User"

    validates :subject, presence: true, length: { maximum: 200 }
    validates :body, presence: true

    def attachment_filename
      attachment&.metadata&.fetch("filename", nil)
    end
  end
end
