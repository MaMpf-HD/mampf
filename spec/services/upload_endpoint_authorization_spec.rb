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
end
