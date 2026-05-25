require "rails_helper"

RSpec.describe("Media", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) do
    create(:confirmed_user, admin: true)
  end
  let!(:medium_ruby) { create(:valid_medium, description: "An introduction to Ruby") }
  let!(:medium_python) { create(:valid_medium, description: "A guide to Python") }

  before do
    sign_in user
  end

  describe "GET /media" do
    let(:lecture) { create(:lecture, :released_for_all) }
    let!(:medium_in_lecture) do
      create(:lecture_medium, teachable: lecture, sort: "LessonMaterial",
                              description: "Content for this lecture")
    end
    let!(:medium_elsewhere) do
      create(:lecture_medium, sort: "LessonMaterial", description: "Content from another source")
    end

    it "returns a successful response" do
      # The media#index action requires a :project parameter to scope the search.
      get media_path(id: lecture.id, project: "lesson_material")
      expect(response).to have_http_status(:ok)
    end

    it "returns only the media associated with the specified lecture" do
      get media_path(id: lecture.id, project: "lesson_material")
      expect(response.body).to include(medium_in_lecture.description)
      expect(response.body).not_to include(medium_elsewhere.description)
    end
  end

  describe "GET /media/search" do
    it "returns a successful response" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response).to have_http_status(:ok)
    end

    it "returns the correct media in the response body" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response.body).to include(medium_ruby.description)
      expect(response.body).not_to include(medium_python.description)
    end
  end

  describe "GET /media/:id/download/:sort" do
    let(:restricted_medium) { create(:lecture_medium, :with_manuscript) }
    let(:free_medium) { create(:lecture_medium, :with_manuscript, :released) }
    let(:video_medium) { create(:lecture_medium, :with_video) }

    it "serves a manuscript attachment through Rails" do
      get download_medium_path(restricted_medium, sort: "manuscript")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"])
        .to include("attachment")
      expect(response.headers["Content-Disposition"])
        .to include(restricted_medium.manuscript_filename)
      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"])
        .to eq("Mon, 01 Jan 1990 00:00:00 GMT")
    end

    it "still serves the download when consumption enqueue fails" do
      expect(Rails.logger).to receive(:error).with(include(
                                                     "medium_id=#{restricted_medium.id}",
                                                     "mode=download",
                                                     "sort=manuscript",
                                                     "redis down"
                                                   ))
      allow(ConsumptionSaver).to receive(:perform_async)
        .and_raise(StandardError, "redis down")

      get download_medium_path(restricted_medium, sort: "manuscript")

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"])
        .to include(restricted_medium.manuscript_filename)
    end

    it "sanitizes the attachment filename from uploaded metadata" do
      allow_any_instance_of(PdfUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get download_medium_path(restricted_medium, sort: "manuscript")
      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("attachment")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end

    it "allows guest downloads for free media" do
      sign_out user

      get download_medium_path(free_medium, sort: "manuscript")

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"])
        .to include(free_medium.manuscript_filename)
      expect(response.headers["Cache-Control"]).not_to eq("no-cache, no-store")
    end

    it "serves a video attachment through Rails" do
      get download_medium_path(video_medium, sort: "video")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("video/mp4")
      expect(response.headers["Content-Disposition"])
        .to include("attachment")
      expect(response.headers["Content-Disposition"])
        .to include(video_medium.video_filename)
    end

    it "rejects guest downloads for restricted media" do
      sign_out user

      get download_medium_path(restricted_medium, sort: "manuscript")

      expect(response).to redirect_to(root_url)
    end

    it "redirects invalid download sorts with a specific alert" do
      get download_medium_path(restricted_medium, sort: "invalid")

      expect(response).to redirect_to(root_url)
      expect(flash[:alert]).to eq(I18n.t("controllers.invalid_download"))
    end
  end

  describe "GET /media/:id/display" do
    let(:restricted_medium) { create(:lecture_medium, :with_manuscript) }
    let(:free_medium) { create(:lecture_medium, :with_manuscript, :released) }

    it "renders a compatibility page that points to the inline manuscript" do
      get display_medium_path(restricted_medium), params: { page: "17" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body)
        .to include(
          "src=\"#{inline_manuscript_medium_path(restricted_medium)}#page=17\""
        )
      expect(response.body)
        .to include("title=\"#{restricted_medium.manuscript_filename}\"")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"])
        .to eq("Mon, 01 Jan 1990 00:00:00 GMT")
    end

    it "preserves named destinations in the inline manuscript fragment" do
      get display_medium_path(restricted_medium), params: { destination: "Theorem 1" }

      expect(response.body)
        .to include(
          "src=\"#{inline_manuscript_medium_path(restricted_medium)}#Theorem%201\""
        )
    end

    it "allows guest access to the compatibility page for free media" do
      sign_out user

      get display_medium_path(free_medium), params: { page: "3" }

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include(
          "src=\"#{inline_manuscript_medium_path(free_medium)}#page=3\""
        )
      expect(response.headers["Cache-Control"]).not_to eq("no-cache, no-store")
    end
  end

  describe "GET /media/:id/manuscript/inline" do
    let(:restricted_medium) { create(:lecture_medium, :with_manuscript) }
    let(:free_medium) { create(:lecture_medium, :with_manuscript, :released) }

    it "serves the manuscript inline through Rails" do
      get inline_manuscript_medium_path(restricted_medium)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Content-Disposition"])
        .to include(restricted_medium.manuscript_filename)
      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
    end

    it "sanitizes the inline filename from uploaded metadata" do
      allow_any_instance_of(PdfUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get inline_manuscript_medium_path(restricted_medium)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("inline")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end

    it "allows guest inline access for free media" do
      sign_out user

      get inline_manuscript_medium_path(free_medium)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Cache-Control"]).not_to eq("no-cache, no-store")
    end
  end

  describe "GET /media/:id/geogebra" do
    let(:restricted_medium) do
      create(:lecture_medium, geogebra_app_name: "classic")
    end
    let(:free_medium) do
      create(:lecture_medium, :released, geogebra_app_name: "classic")
    end
    let(:fake_geogebra) do
      instance_double(
        "Shrine::UploadedFile",
        to_io: File.open(File.join(SPEC_FILES, "manuscript.pdf")),
        storage: double("storage"),
        metadata: {
          "filename" => "demo.ggb",
          "mime_type" => "application/zip"
        }
      )
    end

    before do
      allow_any_instance_of(Medium).to receive(:geogebra).and_return(fake_geogebra)
    end

    it "renders the geogebra page with a Rails-served inline asset" do
      get geogebra_medium_path(restricted_medium)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body)
        .to include("data-filename=\"#{inline_geogebra_medium_path(restricted_medium)}\"")
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"])
        .to eq("Mon, 01 Jan 1990 00:00:00 GMT")
    end

    it "allows guest access to the geogebra page for free media" do
      sign_out user

      get geogebra_medium_path(free_medium)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("data-filename=\"#{inline_geogebra_medium_path(free_medium)}\"")
      expect(response.headers["Cache-Control"]).not_to eq("no-cache, no-store")
    end
  end

  describe "GET /media/:id/geogebra/inline" do
    let(:restricted_medium) { create(:lecture_medium) }
    let(:free_medium) { create(:lecture_medium, :released) }
    let(:fake_geogebra) do
      instance_double(
        "Shrine::UploadedFile",
        to_io: File.open(File.join(SPEC_FILES, "manuscript.pdf")),
        storage: double("storage"),
        metadata: {
          "filename" => "demo.ggb",
          "mime_type" => "application/zip"
        }
      )
    end

    before do
      allow_any_instance_of(Medium).to receive(:geogebra).and_return(fake_geogebra)
    end

    it "serves the geogebra file inline through Rails" do
      get inline_geogebra_medium_path(restricted_medium)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/zip")
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Content-Disposition"]).to include("demo.ggb")
      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
    end

    it "sanitizes the inline geogebra filename from uploaded metadata" do
      hostile_geogebra = instance_double(
        "Shrine::UploadedFile",
        to_io: File.open(File.join(SPEC_FILES, "manuscript.pdf")),
        storage: double("storage"),
        metadata: {
          "filename" => "../demo\r\nfile.ggb",
          "mime_type" => "application/zip"
        }
      )
      allow_any_instance_of(Medium).to receive(:geogebra)
        .and_return(hostile_geogebra)

      get inline_geogebra_medium_path(restricted_medium)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("inline")
      expect(content_disposition).to include("demo")
      expect(content_disposition).to include("file.ggb")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end

    it "allows guest inline geogebra access for free media" do
      sign_out user

      get inline_geogebra_medium_path(free_medium)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("inline")
      expect(response.headers["Cache-Control"]).not_to eq("no-cache, no-store")
    end
  end
end
