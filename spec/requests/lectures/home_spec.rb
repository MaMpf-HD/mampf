require "rails_helper"

RSpec.describe("Lectures::Home", type: :request) do
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: editor) }

  def pdf_upload
    Rack::Test::UploadedFile.new(
      StringIO.new("%PDF-1.4 demo"), "application/pdf",
      original_filename: "program.pdf"
    )
  end

  describe "GET /lectures/:id/home" do
    it "renders the teacher's intro text" do
      lecture.update!(home_intro: "<div>Welcome to the seminar</div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include("Welcome to the seminar")
    end

    it "shows the staff empty-state when no intro is authored yet" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-intro-empty"')
    end

    # Blank Trix wrapper markup must not masquerade as an authored intro,
    # otherwise the nudge (staff) and the fallback (students) both vanish behind
    # an empty card.
    it "still nudges staff when the intro is only blank trix markup" do
      lecture.update!(home_intro: "<div><br></div>")
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-intro-empty"')
      expect(response.body).not_to include('data-testid="lecture-home-intro"')
    end

    it "still shows students the fallback when the intro is only blank markup" do
      lecture.update!(home_intro: "<div><br></div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body).to include('data-testid="lecture-home-fallback-card"')
    end

    it "does not show the staff empty-state to a plain student" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-intro-empty"')
    end
  end

  # The "start here" card is the system's default intro, so it must stand down
  # as soon as the page is not actually empty for the viewer.
  describe "the \"start here\" fallback card" do
    it "shows when the page is genuinely empty for a student" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .to include('data-testid="lecture-home-fallback-card"')
    end

    it "stands down once the teacher has authored an intro" do
      lecture.update!(home_intro: "<div>Welcome to the seminar</div>")
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-fallback-card"')
    end

    it "stands down for staff, who get the nudge instead" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-fallback-card"')
      expect(response.body)
        .to include('data-testid="lecture-home-intro-empty"')
    end
  end

  # Staff never satisfy @show_workflow_content, so without this note they would
  # see nothing where students get the whole registration block — and conclude
  # the page is empty, even though we link them here from the editor.
  describe "the staff note about the student registration view" do
    let!(:campaign) do
      create(:registration_campaign, :open, :with_items,
             campaignable: lecture, items_count: 2,
             description: "Seminarvergabe")
    end

    it "tells staff what students see below the intro" do
      sign_in editor

      get lecture_home_path(lecture)

      expect(response.body)
        .to include('data-testid="lecture-home-staff-workflow-note"')
      expect(response.body).to include("Seminarvergabe")
      expect(response.body).to include(edit_lecture_path(lecture, tab: "groups"))
    end

    it "is not shown to students, who get the real registration block" do
      sign_in student

      get lecture_home_path(lecture)

      expect(response.body)
        .not_to include('data-testid="lecture-home-staff-workflow-note"')
    end

    it "is not shown to staff when the lecture has no campaigns" do
      without_campaign = create(:lecture, :released_for_all, teacher: editor)
      sign_in editor

      get lecture_home_path(without_campaign)

      expect(response.body)
        .not_to include('data-testid="lecture-home-staff-workflow-note"')
    end
  end

  describe "GET /lectures/:id/home_attachment" do
    it "streams the pdf to anyone who may see the home page" do
      lecture.update!(home_attachment: pdf_upload)
      sign_in student

      get lecture_home_attachment_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
    end

    it "redirects when the lecture has no attachment" do
      sign_in editor

      get lecture_home_attachment_path(lecture)

      expect(response).to redirect_to(lecture_home_path(lecture))
      # the lecture exists — only the PDF is gone, so do not claim otherwise
      expect(flash[:alert])
        .to eq(I18n.t("registration.lecture.home.attachment_missing"))
      expect(flash[:alert])
        .not_to eq(I18n.t("registration.lecture.not_found"))
    end

    it "denies access for a non-staff user on an unpublished lecture" do
      lecture.update!(home_attachment: pdf_upload, released: nil)
      sign_in student

      get lecture_home_attachment_path(lecture)

      expect(response).to redirect_to(root_path)
    end
  end
end
