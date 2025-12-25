require "rails_helper"

RSpec.describe("Lectures", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) { create(:confirmed_user, admin: true) }

  # Create 13 calculus courses to test pagination with custom per_page value
  let!(:calculus_courses) do
    (1..13).map { |i| create(:course, title: "Advanced Calculus #{i}") }
  end
  let!(:calculus_lectures) do
    calculus_courses.map { |course| create(:lecture, course: course) }
  end
  let!(:course_algebra) { create(:course, title: "Linear Algebra") }
  let!(:lecture_algebra) { create(:lecture, course: course_algebra) }

  let(:per_page_value) { 10 }

  before do
    sign_in user

    # Stub the ControllerSearcher to use our custom `default_per_page` value
    allow(Search::Searchers::ControllerSearcher).to receive(:search)
      .and_wrap_original do |original_method, **args|
        modified_options = args[:options].merge(default_per_page: per_page_value)
        original_method.call(**args, options: modified_options)
      end
  end

  describe "GET /lectures/search" do
    context "with a JS/XHR request" do
      it "returns a successful response" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct lectures in the response body" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response.body).to include(calculus_courses.first.title)
        expect(response.body).not_to include(lecture_algebra.course.title)
      end
    end

    context "with an HTML request" do
      it "redirects to the root path" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }
        expect(response).to redirect_to(:root)
      end

      it "sets a flash alert" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }
        expect(flash[:alert]).to eq(I18n.t("controllers.search_only_js"))
      end
    end

    context "with a Turbo Stream request" do
      it "renders the initial list replacement" do
        get search_lectures_path,
            params: { search: { fulltext: "Calculus" }, infinite_scroll: true },
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("lecture-search-results-wrapper")
        expect(response.body).to include(calculus_courses.first.title)
        expect(response.body).not_to include(lecture_algebra.course.title)
        expect(response.body).not_to include(calculus_courses[10].title)
      end

      it "appends results on subsequent pages" do
        get search_lectures_path,
            params: { search: { fulltext: "Calculus" }, infinite_scroll: true, page: 2 },
            headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

        puts response.body

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("turbo-stream action=\"append\"")
        expect(response.body).to include("lecture-search-results")
        expect(response.body).to include(calculus_courses[10].title)
        # regex necessary here since "11" includes "1", which is in the first page
        expect(response.body).not_to match(/\b#{Regexp.escape(calculus_courses.first.title)}\b/)
        expect(response.body).not_to include(lecture_algebra.course.title)
      end
    end
  end
end
