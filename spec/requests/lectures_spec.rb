require "rails_helper"

RSpec.describe("Lectures", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:course_calculus) { create(:course, title: "Advanced Calculus") }
  let!(:course_algebra) { create(:course, title: "Linear Algebra") }
  let!(:lecture_calculus) { create(:lecture, course: course_calculus) }
  let!(:lecture_algebra) { create(:lecture, course: course_algebra) }

  before do
    sign_in user
  end

  describe "GET /lectures/search" do
    context "with a JS/XHR request" do
      it "returns a successful response" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct lectures in the response body" do
        get search_lectures_path, params: { search: { fulltext: "Calculus" } }, xhr: true
        expect(response.body).to include(lecture_calculus.course.title)
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
  end
end
