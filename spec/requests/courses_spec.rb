require "rails_helper"

RSpec.describe("Courses", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:course_physics) { create(:course, title: "Quantum Physics") }
  let!(:course_chemistry) { create(:course, title: "Organic Chemistry") }

  before do
    sign_in user
  end

  describe "GET /courses/search" do
    context "with a JS/XHR request" do
      it "returns a successful response" do
        get search_courses_path, params: { search: { fulltext: "Physics" } }, xhr: true
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct courses in the response body" do
        get search_courses_path, params: { search: { fulltext: "Physics" } }, xhr: true
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
