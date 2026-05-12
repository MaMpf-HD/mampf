require "rails_helper"

RSpec.describe("Auth sessions", type: :request) do
  let(:user) { create(:confirmed_user) }

  describe "POST /users/sign_in" do
    it "redirects confirmed users to the start page" do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }

      expect(response).to redirect_to(start_path)
    end

    it "redirects users back to the stored location" do
      get news_path
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }

      expect(response).to redirect_to(news_path)
    end

    it "does not sign in users with invalid credentials" do
      post user_session_path, params: {
        user: { email: user.email, password: "wrong-password" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("data-cy=\"login-form\"")
    end

    it "renders a Turbo Stream flash for invalid credentials" do
      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(I18n.t("devise.failure.invalid"))
    end
  end

  describe "sign out" do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: user.password }
      }
    end

    it "signs users out via DELETE" do
      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)

      get news_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
