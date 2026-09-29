require "rails_helper"

RSpec.describe("Users", type: :request) do
  let(:viewer) { create(:confirmed_user) }
  let(:teacher_user) { create(:confirmed_user, name: "Ada") }
  let!(:lecture) { create(:lecture, teacher: teacher_user) }
  let(:fake_image) do
    instance_double(
      "Shrine::UploadedFile",
      to_io: File.open(File.join(SPEC_FILES, "image.png")),
      storage: double("storage"),
      metadata: {
        "filename" => "teacher.png",
        "mime_type" => "image/png"
      }
    )
  end

  before do
    sign_in viewer
    allow_any_instance_of(User).to receive(:original_image_file)
      .and_return(fake_image)
    allow_any_instance_of(User).to receive(:normalized_image_file)
      .and_return(fake_image)
    allow_any_instance_of(User).to receive(:image_filename)
      .and_return("teacher.png")
  end

  describe "GET /users/:id/image/:variant" do
    it "serves user images inline through Rails" do
      get image_user_path(teacher_user, variant: "original")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
    end

    it "returns not found for missing users" do
      get image_user_path(id: teacher_user.id + 1000, variant: "original")

      expect(response).to have_http_status(:not_found)
    end

    describe "original-variant access control" do
      let(:original_file) do
        instance_double("Shrine::UploadedFile",
                        to_io: File.open(File.join(SPEC_FILES, "image.png")),
                        storage: double("storage"),
                        metadata: { "filename" => "original.png",
                                    "mime_type" => "image/png" })
      end
      let(:normalized_file) do
        instance_double("Shrine::UploadedFile",
                        to_io: File.open(File.join(SPEC_FILES, "image.png")),
                        storage: double("storage"),
                        metadata: { "filename" => "normalized.png",
                                    "mime_type" => "image/png" })
      end

      before do
        allow_any_instance_of(User).to receive(:original_image_file)
          .and_return(original_file)
        allow_any_instance_of(User).to receive(:normalized_image_file)
          .and_return(normalized_file)
      end

      it "downgrades a non-owner's original request to the normalized variant" do
        get image_user_path(teacher_user, variant: "original")

        expect(response.headers["Content-Disposition"]).to include("normalized.png")
      end

      it "serves admins the requested original variant" do
        sign_in create(:confirmed_user, admin: true)

        get image_user_path(teacher_user, variant: "original")

        expect(response.headers["Content-Disposition"]).to include("original.png")
      end
    end
  end

  describe "GET /users/teacher/:teacher_id" do
    it "renders the teacher profile image through a Rails route" do
      get teacher_path(teacher_id: teacher_user.id)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("src=\"#{image_user_path(teacher_user, variant: "original")}\"")
    end
  end
end
