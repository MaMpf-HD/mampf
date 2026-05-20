require "rails_helper"

RSpec.describe("Auth sessions", type: :request) do
  let(:password) { "Password123!" }
  let(:user) { create(:confirmed_user, password: password) }
  let(:failed_attempts_before_last_warning) do
    user.class.maximum_attempts - 2
  end
  let(:unlock_in_words) do
    ActionController::Base.helpers.distance_of_time_in_words(
      Time.current,
      Time.current + Devise.unlock_in
    )
  end

  describe "POST /users/sign_in" do
    it "redirects confirmed users to the start page" do
      post user_session_path, params: {
        user: { email: user.email, password: password }
      }

      expect(response).to redirect_to(start_path)
    end

    it "redirects users back to the stored location" do
      get news_path
      expect(response).to redirect_to(new_user_session_path)

      post user_session_path, params: {
        user: { email: user.email, password: password }
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

    it "renders a Turbo Stream flash for the last attempt before lockout" do
      user.update!(failed_attempts: failed_attempts_before_last_warning)

      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(I18n.t("devise.failure.last_attempt"))
    end

    it "renders a Turbo Stream flash for locked accounts" do
      user.lock_access!

      post user_session_path,
           params: { user: { email: user.email, password: password } },
           as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(
        I18n.t("devise.failure.locked_with_email_and_time",
               unlock_in: unlock_in_words)
      )
    end
  end

  describe "sign out" do
    before do
      post user_session_path, params: {
        user: { email: user.email, password: password }
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
