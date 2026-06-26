require "rails_helper"

RSpec.describe("UploadRoutes", type: :request) do
  let(:user) { create(:confirmed_user, locale: "en") }
  let(:scanner) { instance_double(ClamavScanner) }
  let(:restricted_uploads) do
    {
      "/screenshots/upload" => Rack::Test::UploadedFile.new(
        File.join(SPEC_FILES, "image.png"),
        "image/png"
      ),
      "/videos/upload" => Rack::Test::UploadedFile.new(
        File.join(SPEC_FILES, "talk.mp4"),
        "video/mp4"
      ),
      "/pdfs/upload" => Rack::Test::UploadedFile.new(
        File.join(SPEC_FILES, "manuscript.pdf"),
        "application/pdf"
      ),
      "/ggbs/upload" => Rack::Test::UploadedFile.new(
        File.join(SPEC_FILES, "manuscript.pdf"),
        "application/zip"
      ),
      "/corrections/upload" => Rack::Test::UploadedFile.new(
        File.join(SPEC_FILES, "manuscript.pdf"),
        "application/pdf"
      )
    }
  end

  [
    "/screenshots/upload",
    "/profile_image/upload",
    "/videos/upload",
    "/pdfs/upload",
    "/ggbs/upload",
    "/submissions/upload",
    "/corrections/upload"
  ].each do |path|
    it "redirects anonymous requests for #{path}" do
      post path

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to eq("http://www.example.com/users/sign_in")
    end
  end

  describe "internal upload authorization" do
    it "returns unauthorized for anonymous requests" do
      get "/internal/upload-authorizations/video"

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["X-Upload-Authorization-Message"]).to eq(
        I18n.t("devise.failure.unauthenticated")
      )
    end

    it "returns not found for unknown uploaders" do
      sign_in user

      get "/internal/upload-authorizations/unknown"

      expect(response).to have_http_status(:not_found)
    end

    it "rejects low-privilege users for restricted uploaders" do
      sign_in user

      get "/internal/upload-authorizations/video", params: { locale: user.locale }

      expect(response).to have_http_status(:forbidden)
      expect(response.headers["X-Upload-Authorization-Message"]).to eq(
        I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
      )
    end

    it "allows low-privilege users for unrestricted uploaders" do
      sign_in user

      get "/internal/upload-authorizations/profile_image"

      expect(response).to have_http_status(:not_found)
    end

    context "when the user is an editor" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          create(:course, :with_editor_by_id, editor_id: editor.id)
          editor.reload
        end
      end

      it "allows restricted uploaders" do
        sign_in user

        get "/internal/upload-authorizations/pdf", params: { locale: user.locale }

        expect(response).to have_http_status(:no_content)
      end
    end

    context "when the user only edits an existing medium" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          medium = create(:valid_medium)
          medium.editors << editor
          editor.reload
        end
      end

      it "still allows video as a temporary compromise" do
        sign_in user

        get "/internal/upload-authorizations/video", params: { locale: user.locale }

        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe "temporary coarse endpoint authorization" do
    before do
      sign_in user
      allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
      allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)
    end

    [
      "/screenshots/upload",
      "/videos/upload",
      "/pdfs/upload",
      "/ggbs/upload",
      "/corrections/upload"
    ].each do |path|
      it "rejects low-privilege users for #{path}" do
        post path, params: { file: restricted_uploads.fetch(path) }

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(
          I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
        )
      end
    end

    it "still allows low-privilege users on /submissions/upload" do
      upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                            "application/pdf")

      post "/submissions/upload", params: { file: upload }

      expect(response).to have_http_status(:ok)
    end

    it "still allows low-privilege users on /profile_image/upload" do
      upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "image.png"),
                                            "image/png")

      post "/profile_image/upload", params: { file: upload }

      expect(response).to have_http_status(:ok)
    end

    context "when the user is an editor" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          create(:course, :with_editor_by_id, editor_id: editor.id)
          editor.reload
        end
      end

      [
        "/screenshots/upload",
        "/videos/upload",
        "/pdfs/upload",
        "/ggbs/upload"
      ].each do |path|
        it "allows #{path}" do
          post path, params: { file: restricted_uploads.fetch(path) }

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the user only edits an existing medium" do
        let(:user) do
          create(:confirmed_user, locale: "en").tap do |editor|
            medium = create(:valid_medium)
            medium.editors << editor
            editor.reload
          end
        end

        it "still allows /videos/upload as a temporary compromise" do
          post "/videos/upload",
               params: { file: restricted_uploads.fetch("/videos/upload") }

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when the user is a tutor" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |tutor|
          create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id)
          tutor.reload
        end
      end

      it "allows /corrections/upload" do
        post "/corrections/upload",
             params: { file: restricted_uploads.fetch("/corrections/upload") }

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is a speaker" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |speaker|
          create(:talk, speaker_ids: [speaker.id])
          speaker.reload
        end
      end

      it "allows /videos/upload" do
        post "/videos/upload",
             params: { file: restricted_uploads.fetch("/videos/upload") }

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
