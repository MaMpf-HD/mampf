require "rails_helper"

RSpec.describe(UploadEndpointAuthorization) do
  describe ".authorized?" do
    let(:user) { create(:confirmed_user) }

    it "allows the intentionally open uploaders for any authenticated user" do
      expect(described_class.authorized?(uploader_class: SubmissionUploader,
                                         user: user)).to be(true)
      expect(described_class.authorized?(uploader_class: ProfileimageUploader,
                                         user: user)).to be(true)
    end

    it "still gates restricted uploaders against a non-editor" do
      expect(described_class.authorized?(uploader_class: PdfUploader,
                                         user: user)).to be(false)
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
end
