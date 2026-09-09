require "rails_helper"

RSpec.describe(UploadEndpointAuthorization) do
  describe ".authorized?" do
    let(:user) { create(:confirmed_user) }

    it "keeps manuscript submissions open to any authenticated user" do
      expect(described_class.authorized?(uploader_class: SubmissionUploader,
                                         user: user)).to be(true)
    end

    it "gates restricted uploaders (incl. profile images) against a non-editor" do
      expect(described_class.authorized?(uploader_class: PdfUploader,
                                         user: user)).to be(false)
      expect(described_class.authorized?(uploader_class: ProfileimageUploader,
                                         user: user)).to be(false)
    end

    it "allows content editors to upload profile images" do
      admin = create(:confirmed_user, admin: true)

      expect(described_class.authorized?(uploader_class: ProfileimageUploader,
                                         user: admin)).to be(true)
    end

    it "fails closed (raises) for an unhandled uploader class" do
      unknown = Class.new do
        def self.name
          "UnknownUploader"
        end
      end

      expect do
        described_class.authorized?(uploader_class: unknown, user: user)
      end.to raise_error(ArgumentError, /Unhandled uploader/)
    end
  end

  describe ".intent_authorized?" do
    let(:user) { create(:confirmed_user) }
    let(:medium) { create(:valid_medium) }

    def intent(minted_for: user, uploader_class: VideoUploader, target: nil,
               action: nil)
      UploadIntent.parse(UploadIntent.mint(user: minted_for,
                                           uploader_class: uploader_class,
                                           target: target, action: action))
    end

    it "refuses an upload that names no intent" do
      expect(described_class.intent_authorized?(intent: nil,
                                                uploader_class: VideoUploader,
                                                user: user)).to be(false)
    end

    it "refuses an intent minted for somebody else" do
      other = intent(minted_for: create(:confirmed_user))

      expect(described_class.intent_authorized?(intent: other,
                                                uploader_class: VideoUploader,
                                                user: user)).to be(false)
    end

    it "refuses an intent minted for another uploader" do
      expect(described_class.intent_authorized?(intent: intent,
                                                uploader_class: PdfUploader,
                                                user: user)).to be(false)
    end

    it "refuses an intent that names no record at all" do
      expect(described_class.intent_authorized?(intent: intent,
                                                uploader_class: VideoUploader,
                                                user: user)).to be(false)
    end

    it "asks about the record a form is about to create" do
      assignment = create(:assignment, :with_lecture)
      submitting = intent(uploader_class: SubmissionUploader,
                          target: Submission.new(assignment: assignment))

      expect(described_class.intent_authorized?(intent: submitting,
                                                uploader_class: SubmissionUploader,
                                                user: user)).to be(false)

      assignment.lecture.users << user
      user.reload

      expect(described_class.intent_authorized?(intent: submitting,
                                                uploader_class: SubmissionUploader,
                                                user: user)).to be(true)
    end

    it "asks the target whether the user may still do what the form offered" do
      aimed = intent(target: medium)

      expect(described_class.intent_authorized?(intent: aimed,
                                                uploader_class: VideoUploader,
                                                user: user)).to be(false)

      medium.editors << user

      expect(described_class.intent_authorized?(intent: intent(target: medium.reload),
                                                uploader_class: VideoUploader,
                                                user: user)).to be(true)
    end

    it "refuses an action the user may not take on the target" do
      submission = create(:submission, :with_assignment, :with_tutorial)

      expect(described_class.intent_authorized?(
               intent: intent(uploader_class: CorrectionUploader, target: submission,
                              action: :add_correction),
               uploader_class: CorrectionUploader, user: user
             )).to be(false)
    end

    it "refuses a target class that cannot be an upload target" do
      lecture = create(:lecture)
      aimed = intent(target: lecture)

      expect(described_class.intent_authorized?(intent: aimed,
                                                uploader_class: VideoUploader,
                                                user: user)).to be(false)
    end
  end
end
