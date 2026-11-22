require "rails_helper"

RSpec.describe("Tags", type: :request) do
  let(:user) { create(:confirmed_user, admin: true) }
  let!(:tag_math) { create(:tag, title: "Mathematics") }
  let!(:tag_physics) { create(:tag, title: "Physics") }

  before do
    sign_in user
  end

  describe "GET /tags/search" do
    context "with a JS/XHR request" do
      it "returns a successful response" do
        get search_tags_path, params: { search: { fulltext: "Math" } }, xhr: true
        expect(response).to have_http_status(:ok)
      end

      it "returns the correct tags in the response body" do
        get search_tags_path, params: { search: { fulltext: "Math" } }, xhr: true
        expect(response.body).to include(tag_math.title)
        expect(response.body).not_to include(tag_physics.title)
      end
    end

    context "with an HTML request" do
      it "redirects to the root path" do
        get search_tags_path, params: { search: { fulltext: "Math" } }
        expect(response).to redirect_to(:root)
      end

      it "sets a flash alert" do
        get search_tags_path, params: { search: { fulltext: "Math" } }
        expect(flash[:alert]).to eq(I18n.t("controllers.search_only_js"))
      end
    end
  end

  describe "POST /tags/:id/take_random_quiz" do
    let(:quiz) { create(:valid_random_quiz) }

    it "starts a random quiz for the tag" do
      allow_any_instance_of(Tag).to receive(:create_random_quiz!)
        .and_return(quiz)

      post tag_random_quiz_path(tag_math)

      expect(response).to redirect_to(take_quiz_path(quiz))
    end

    it "creates no quiz on GET" do
      expect_any_instance_of(Tag).not_to receive(:create_random_quiz!)

      get tag_random_quiz_path(tag_math)

      expect(flash[:alert]).to eq(I18n.t("controllers.no_page"))
    end
  end
end
