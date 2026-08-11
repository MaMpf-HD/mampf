require "rails_helper"

RSpec.describe("Courses", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:course_physics) { create(:course, title: "Quantum Physics") }
  let!(:course_chemistry) { create(:course, title: "Organic Chemistry") }

  before do
    sign_in user
  end

  describe "GET /courses/:id/image/:variant" do
    let(:course) { create(:course) }
    let(:storage) do
      double("storage").tap do |fake_storage|
        allow(fake_storage).to receive(:path)
          .with("course-image")
          .and_return(File.join(SPEC_FILES, "image.png"))
      end
    end
    let(:fake_image) do
      instance_double(
        "Shrine::UploadedFile",
        id: "course-image",
        to_io: StringIO.new(File.binread(File.join(SPEC_FILES, "image.png"))),
        storage: storage,
        metadata: {
          "filename" => "course.png",
          "mime_type" => "image/png"
        }
      )
    end

    before do
      allow_any_instance_of(Course).to receive(:original_image_file)
        .and_return(fake_image)
      allow_any_instance_of(Course).to receive(:normalized_image_file)
        .and_return(fake_image)
      allow_any_instance_of(Course).to receive(:image_filename)
        .and_return("course.png")
    end

    it "serves course images inline through Rails" do
      get image_course_path(course, variant: "normalized")

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("image/png")
      expect(response.headers["Content-Disposition"]).to include("inline")
    end

    it "renders the course edit image preview through a Rails route" do
      get edit_course_path(course)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include("src=\"#{image_course_path(course, variant: "original")}\"")
    end
  end

  describe "GET /courses/search" do
    context "from within the results frame" do
      let(:frame_headers) { { "Turbo-Frame" => "courses-search-results" } }

      it "returns a successful response" do
        get search_courses_path, params: { search: { fulltext: "Physics" } },
                                 headers: frame_headers
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct courses in the response body" do
        get search_courses_path, params: { search: { fulltext: "Physics" } },
                                 headers: frame_headers
        expect(response.body).to include(course_physics.title)
        expect(response.body).not_to include(course_chemistry.title)
      end
    end

    context "with an HTML request" do
      it "redirects to the root path" do
        get search_courses_path, params: { search: { fulltext: "Physics" } }
        expect(response).to redirect_to(:root)
      end

      it "sets a flash alert" do
        get search_courses_path, params: { search: { fulltext: "Physics" } }
        expect(flash[:alert]).to eq(I18n.t("controllers.search_only_js"))
      end
    end
  end

  describe "GET /courses/:id/render_question_counter" do
    let(:course) { create(:course) }
    let(:tag) { create(:tag) }

    def counter_text(count)
      allow_any_instance_of(Course).to receive(:question_count).and_return(count)

      get(render_question_counter_path(course), params: { tag_ids: [tag.id] },
                                                as: :turbo_stream)

      expect(response).to have_http_status(:success)
      Nokogiri::HTML(response.body).text.strip
    end

    it "names no question when there is none" do
      expect(counter_text(0)).to eq("No question has been found for the selected tags.")
    end

    it "keeps the singular for a single question" do
      expect(counter_text(1)).to eq("One question has been found for the selected tags.")
    end

    it "counts the questions otherwise" do
      expect(counter_text(5)).to eq("5 questions have been found for the selected tags.")
    end
  end

  describe "XSS protections" do
    let(:xss_payload) { "<div id='test-xss-xyz123'><script>alert('course-xss')</script></div>" }
    let!(:xss_course) do
      create(:course, title: "XSS Course", organizational: true,
                      organizational_concept: xss_payload)
    end

    it "escapes or strips script tags from course organizational concept in edit view" do
      get edit_course_path(xss_course)
      expect(response).to be_successful
      expect(response.body).not_to include("<script>alert('course-xss')</script>")
    end
  end
end
