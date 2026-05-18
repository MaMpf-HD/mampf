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
end
