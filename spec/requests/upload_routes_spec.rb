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

    it "rejects low-privilege users for /internal/upload-authorizations/profile_image" do
      sign_in user

      get "/internal/upload-authorizations/profile_image",
          params: { locale: user.locale }

      expect(response).to have_http_status(:forbidden)
      expect(response.headers["X-Upload-Authorization-Message"]).to eq(
        I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
      )
    end

    it "answers for submissions, which any signed-in user may make" do
      sign_in user

      get "/internal/upload-authorizations/submission", params: { locale: user.locale }

      expect(response).to have_http_status(:no_content)
    end

    it "turns away a submission intent for a lecture the user does not attend" do
      assignment = create(:assignment, :with_lecture)
      sign_in user
      token = UploadIntent.mint(user: user, uploader_class: SubmissionUploader,
                                target: Submission.new(assignment: assignment))

      get "/internal/upload-authorizations/submission",
          params: { locale: user.locale },
          headers: { "X-Upload-Intent" => token }

      expect(response).to have_http_status(:forbidden)
    end

    context "when the request carries an intent" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          create(:course, :with_editor_by_id, editor_id: editor.id)
          editor.reload
        end
      end
      let(:medium) { create(:valid_medium) }

      before { sign_in user }

      it "turns away a medium the user may not edit, before the body arrives" do
        token = UploadIntent.mint(user: user, uploader_class: VideoUploader,
                                  target: medium)

        get "/internal/upload-authorizations/video", params: { locale: user.locale },
                                                     headers: { "X-Upload-Intent" => token }

        expect(response).to have_http_status(:forbidden)
      end

      it "lets through the medium the user edits" do
        medium.editors << user
        token = UploadIntent.mint(user: user, uploader_class: VideoUploader,
                                  target: medium)

        get "/internal/upload-authorizations/video", params: { locale: user.locale },
                                                     headers: { "X-Upload-Intent" => token }

        expect(response).to have_http_status(:no_content)
      end
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

      it "allows profile image uploads" do
        sign_in user

        get "/internal/upload-authorizations/profile_image",
            params: { locale: user.locale }

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

    describe "ActiveStorage direct uploads" do
      it "returns unauthorized for anonymous requests" do
        get "/internal/upload-authorizations/active_storage"

        expect(response).to have_http_status(:unauthorized)
        expect(response.headers["X-Upload-Authorization-Message"]).to eq(
          I18n.t("devise.failure.unauthenticated")
        )
      end

      it "rejects low-privilege users" do
        sign_in user

        get "/internal/upload-authorizations/active_storage",
            params: { locale: user.locale }

        expect(response).to have_http_status(:forbidden)
        expect(response.headers["X-Upload-Authorization-Message"]).to eq(
          I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
        )
      end

      context "when the user is an editor" do
        let(:user) do
          create(:confirmed_user, locale: "en").tap do |editor|
            create(:course, :with_editor_by_id, editor_id: editor.id)
            editor.reload
          end
        end

        it "allows the direct-upload endpoint" do
          sign_in user

          get "/internal/upload-authorizations/active_storage",
              params: { locale: user.locale }

          expect(response).to have_http_status(:no_content)
        end
      end
    end
  end

  describe "endpoint authorization" do
    before do
      sign_in user
      allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
      allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)
    end

    def intent_header(uploader_class, target: nil, action: nil, minted_for: user)
      {
        "X-Upload-Intent" => UploadIntent.mint(user: minted_for,
                                               uploader_class: uploader_class,
                                               target: target, action: action)
      }
    end

    uploaders = {
      "/screenshots/upload" => ScreenshotUploader,
      "/videos/upload" => VideoUploader,
      "/pdfs/upload" => PdfUploader,
      "/ggbs/upload" => GeogebraUploader,
      "/corrections/upload" => CorrectionUploader
    }

    uploaders.each_key do |path|
      it "rejects low-privilege users for #{path}" do
        post path, params: { file: restricted_uploads.fetch(path) },
                   headers: intent_header(uploaders.fetch(path))

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(
          I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
        )
      end
    end

    it "allows a student to upload for an assignment of their own lecture" do
      upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                            "application/pdf")
      assignment = create(:assignment, :with_lecture)
      assignment.lecture.users << user

      post "/submissions/upload",
           params: { file: upload },
           headers: intent_header(SubmissionUploader,
                                  target: Submission.new(assignment: assignment))

      expect(response).to have_http_status(:ok)
    end

    it "rejects low-privilege users on /profile_image/upload" do
      upload = Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "image.png"),
                                            "image/png")

      post "/profile_image/upload", params: { file: upload },
                                    headers: intent_header(ProfileimageUploader,
                                                           target: user)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include(
        I18n.t("submission.upload_failure_unauthorized", locale: user.locale)
      )
    end

    context "when the user is an editor" do
      let(:course) { create(:course) }
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          course.editors << editor
          editor.reload
        end
      end
      # The course image is uploaded from the course itself, the rest from the
      # form of a medium that will hang under it.
      let(:targets) do
        {
          "/screenshots/upload" => course,
          "/videos/upload" => Medium.new(teachable: course),
          "/pdfs/upload" => Medium.new(teachable: course),
          "/ggbs/upload" => Medium.new(teachable: course)
        }
      end

      [
        "/screenshots/upload",
        "/videos/upload",
        "/pdfs/upload",
        "/ggbs/upload"
      ].each do |path|
        it "allows #{path}" do
          post path, params: { file: restricted_uploads.fetch(path) },
                     headers: intent_header(uploaders.fetch(path),
                                            target: targets.fetch(path))

          expect(response).to have_http_status(:ok)
        end
      end

      context "when the user only edits an existing medium" do
        let(:medium) { create(:valid_medium) }
        let(:user) do
          create(:confirmed_user, locale: "en").tap do |editor|
            medium.editors << editor
            editor.reload
          end
        end

        it "allows /videos/upload for that medium" do
          post "/videos/upload",
               params: { file: restricted_uploads.fetch("/videos/upload") },
               headers: intent_header(VideoUploader, target: medium)

          expect(response).to have_http_status(:ok)
        end

        it "refuses /videos/upload for a medium somebody else edits" do
          post "/videos/upload",
               params: { file: restricted_uploads.fetch("/videos/upload") },
               headers: intent_header(VideoUploader, target: create(:valid_medium))

          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    context "when the user is a tutor" do
      let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: user.id) }
      let(:user) { create(:confirmed_user, locale: "en") }
      let(:submission) do
        create(:submission, tutorial: tutorial,
                            assignment: create(:assignment, lecture: tutorial.lecture))
      end

      it "allows /corrections/upload for a submission of their tutorial" do
        submission
        user.reload

        post "/corrections/upload",
             params: { file: restricted_uploads.fetch("/corrections/upload") },
             headers: intent_header(CorrectionUploader, target: submission,
                                                        action: :add_correction)

        expect(response).to have_http_status(:ok)
      end

      it "refuses /corrections/upload for a submission of another tutorial" do
        submission
        user.reload
        other = create(:submission, :with_assignment, :with_tutorial)

        post "/corrections/upload",
             params: { file: restricted_uploads.fetch("/corrections/upload") },
             headers: intent_header(CorrectionUploader, target: other,
                                                        action: :add_correction)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is a speaker" do
      let(:talk) { create(:talk, speaker_ids: [user.id]) }
      let(:user) { create(:confirmed_user, locale: "en") }

      it "allows /videos/upload for a medium of their talk" do
        talk
        user.reload

        post "/videos/upload",
             params: { file: restricted_uploads.fetch("/videos/upload") },
             headers: intent_header(VideoUploader, target: Medium.new(teachable: talk))

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "signed upload intent" do
    include ActiveSupport::Testing::TimeHelpers

    let(:user) do
      create(:confirmed_user, locale: "en").tap do |editor|
        create(:course, :with_editor_by_id, editor_id: editor.id)
        editor.reload
      end
    end
    let(:upload) { restricted_uploads.fetch("/videos/upload") }

    before do
      sign_in user
      allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
      allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)
    end

    def post_video(token)
      post("/videos/upload", params: { file: upload },
                             headers: { "X-Upload-Intent" => token })
    end

    it "refuses an upload that names no intent" do
      post "/videos/upload", params: { file: upload }

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses an intent that was minted for somebody else" do
      post_video(UploadIntent.mint(user: create(:confirmed_user),
                                   uploader_class: VideoUploader))

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses an intent that was minted for another uploader" do
      post_video(UploadIntent.mint(user: user, uploader_class: PdfUploader))

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses a token that has been tampered with" do
      token = UploadIntent.mint(user: user, uploader_class: VideoUploader)

      post_video("#{token}x")

      expect(response).to have_http_status(:forbidden)
    end

    it "says so when the page has been open past the lifetime" do
      token = travel_to(2.days.ago) do
        UploadIntent.mint(user: user, uploader_class: VideoUploader,
                          target: create(:valid_medium))
      end

      post_video(token)

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include(
        I18n.t("submission.upload_failure_expired", locale: user.locale).strip
      )
    end

    context "when the intent names a submission that does not exist yet" do
      let(:assignment) { create(:assignment, :with_lecture) }
      let(:manuscript) do
        Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                     "application/pdf")
      end

      def post_submission
        post("/submissions/upload",
             params: { file: manuscript },
             headers: {
               "X-Upload-Intent" => UploadIntent.mint(
                 user: user, uploader_class: SubmissionUploader,
                 target: Submission.new(assignment: assignment)
               )
             })
      end

      it "refuses a student who does not attend the lecture" do
        post_submission

        expect(response).to have_http_status(:forbidden)
      end

      it "allows a student of the lecture" do
        assignment.lecture.users << user

        post_submission

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the intent names a medium" do
      let(:medium) { create(:valid_medium) }

      it "refuses a medium the user may not edit" do
        post_video(UploadIntent.mint(user: user, uploader_class: VideoUploader,
                                     target: medium))

        expect(response).to have_http_status(:forbidden)
      end

      it "allows the medium the user edits" do
        medium.editors << user

        post_video(UploadIntent.mint(user: user, uploader_class: VideoUploader,
                                     target: medium))

        expect(response).to have_http_status(:ok)
      end

      it "refuses a medium that has been deleted since" do
        medium.editors << user
        token = UploadIntent.mint(user: user, uploader_class: VideoUploader,
                                  target: medium)
        medium.destroy

        post_video(token)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "a file sent straight to a record instead of an upload endpoint" do
    let(:scanner) { instance_double(ClamavScanner) }
    let(:manuscript) do
      Rack::Test::UploadedFile.new(File.join(SPEC_FILES, "manuscript.pdf"),
                                   "application/pdf")
    end

    before do
      allow(MalwareScanGate).to receive(:scanner).and_return(scanner)
      allow(scanner).to receive(:scan).and_return(UploadScanResult.clean)
    end

    it "does not become a manuscript for a speaker who may edit the medium" do
      medium = create(:talk_medium)
      speaker = create(:confirmed_user, locale: "en")
      medium.teachable.speakers << speaker
      sign_in speaker.reload

      patch "/media/#{medium.id}", params: { medium: { manuscript: manuscript } }

      expect(medium.reload.manuscript).to be_nil
      expect(response).to redirect_to(root_url)
      expect(flash[:alert]).to eq(I18n.t("submission.upload_failure_unauthorized"))
    end

    it "does not become a student's submission either" do
      submission = create(:submission, :with_assignment, :with_tutorial)
      student = create(:confirmed_user, locale: "en")
      submission.users << student
      sign_in student.reload

      patch "/submissions/#{submission.id}",
            params: { submission: { tutorial_id: submission.tutorial_id,
                                    manuscript: manuscript } }

      expect(submission.reload.manuscript).to be_nil
      expect(response).to redirect_to(root_url)
    end
  end

  describe "ActiveStorage direct-upload endpoint (in-app belt)" do
    let(:blob_attributes) do
      {
        filename: "image.png",
        byte_size: 123,
        checksum: "1B2M2Y8AsgTpgAmY7PhCfg==",
        content_type: "image/png"
      }
    end

    it "rejects anonymous requests" do
      post "/rails/active_storage/direct_uploads", params: { blob: blob_attributes }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects low-privilege users" do
      sign_in user

      post "/rails/active_storage/direct_uploads", params: { blob: blob_attributes }

      expect(response).to have_http_status(:forbidden)
    end

    context "when the user is an editor" do
      let(:user) do
        create(:confirmed_user, locale: "en").tap do |editor|
          create(:course, :with_editor_by_id, editor_id: editor.id)
          editor.reload
        end
      end

      it "allows the upload and creates a blob" do
        sign_in user

        post "/rails/active_storage/direct_uploads", params: { blob: blob_attributes }

        expect(response).to have_http_status(:ok)
        expect(ActiveStorage::Blob.exists?(filename: "image.png")).to be(true)
      end
    end
  end
end
