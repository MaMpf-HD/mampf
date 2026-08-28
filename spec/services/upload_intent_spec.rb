require "rails_helper"

RSpec.describe(UploadIntent) do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:confirmed_user) }

  describe ".parse" do
    it "reads back what was minted" do
      medium = create(:valid_medium)
      token = described_class.mint(user: user, uploader_class: VideoUploader,
                                   target: medium, action: :update)

      intent = described_class.parse(token)

      expect(intent).to have_attributes(user_id: user.id, uploader: "VideoUploader",
                                        target_type: "Medium", target_id: medium.id,
                                        action: :update)
      expect(intent.target).to eq(medium)
    end

    it "returns nothing for a token that was tampered with" do
      token = described_class.mint(user: user, uploader_class: VideoUploader)

      expect(described_class.parse("#{token}x")).to be_nil
    end

    it "returns nothing for a token signed with another purpose" do
      token = Rails.application.message_verifier("something_else")
                   .generate({ user_id: user.id }, purpose: "something_else")

      expect(described_class.parse(token)).to be_nil
    end

    it "returns nothing once the token has expired" do
      token = travel_to(2.days.ago) do
        described_class.mint(user: user, uploader_class: VideoUploader)
      end

      expect(described_class.parse(token)).to be_nil
    end

    it "returns nothing when no token was sent" do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse("")).to be_nil
    end
  end

  describe "a target that does not exist yet" do
    it "is rebuilt from the ids that decide who may create it" do
      assignment = create(:assignment, :with_lecture)
      intent = described_class.parse(
        described_class.mint(user: user, uploader_class: SubmissionUploader,
                             target: Submission.new(assignment: assignment))
      )

      expect(intent).to be_targeted
      expect(intent.action).to eq(:create)
      expect(intent.target).to have_attributes(class: Submission, id: nil,
                                               assignment_id: assignment.id)
    end

    it "is nothing at all once the schema has moved on" do
      intent = described_class.parse(
        described_class.mint(user: user, uploader_class: SubmissionUploader,
                             target: Submission.new)
      )
      allow(Submission).to receive(:new).and_raise(ActiveModel::UnknownAttributeError.new(
                                                     Submission.new, "gone_id"
                                                   ))

      expect(intent.target).to be_nil
    end
  end

  describe "#for_user?" do
    it "holds only for the user it was minted for" do
      intent = described_class.parse(
        described_class.mint(user: user, uploader_class: VideoUploader)
      )

      expect(intent).to be_for_user(user)
      expect(intent).not_to be_for_user(create(:confirmed_user))
      expect(intent).not_to be_for_user(nil)
    end
  end

  describe "#for_uploader?" do
    it "holds only for the uploader it was minted for" do
      intent = described_class.parse(
        described_class.mint(user: user, uploader_class: VideoUploader)
      )

      expect(intent).to be_for_uploader(VideoUploader)
      expect(intent).not_to be_for_uploader(PdfUploader)
    end
  end

  describe ".from_request" do
    it "reads the intent off the request header" do
      token = described_class.mint(user: user, uploader_class: VideoUploader)
      request = Rack::Request.new(Rack::MockRequest.env_for("/videos/upload",
                                                            "HTTP_X_UPLOAD_INTENT" => token))

      expect(described_class.from_request(request).user_id).to eq(user.id)
    end
  end
end
