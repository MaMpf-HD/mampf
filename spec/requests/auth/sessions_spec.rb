require "rails_helper"

RSpec.describe("Auth sessions", type: :request) do
  let(:password) { "Password123!" }
  let(:user) { create(:confirmed_user, password: password) }
  let(:unlock_in_words) do
    ActionController::Base.helpers.distance_of_time_in_words(
      Time.current,
      Time.current + Devise.unlock_in
    )
  end

  describe "POST /users/sign_in" do
    it "sends a first-time visitor to their profile" do
      post user_session_path, params: {
        user: { email: user.email, password: password }
      }

      expect(response).to redirect_to(edit_profile_path)
      expect(flash[:notice]).to eq(I18n.t("profile.please_update"))
    end

    it "redirects returning users to the start page" do
      post user_session_path, params: {
        user: { email: user.email, password: password }
      }
      delete destroy_user_session_path

      post user_session_path, params: {
        user: { email: user.email, password: password }
      }

      expect(response).to redirect_to(start_path)
      expect(flash[:notice]).to be_nil
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

    it "keeps the failure generic when a locked account is guessed at" do
      user.lock_access!

      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream

      expect(response.body).to include(I18n.t("devise.failure.invalid"))
      expect(response.body).not_to include("locked")
    end

    it "answers alike for a locked account and an unknown address" do
      user.lock_access!

      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream
      locked_account = response.body

      post user_session_path,
           params: { user: { email: "no-such-user@example.com",
                             password: "wrong-password" } },
           as: :turbo_stream

      expect(response.body).to eq(locked_account)
    end

    it "answers in the language the visitor picked" do
      get new_user_session_path, params: { locale: "en" }

      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream

      expect(response.body).to include(
        I18n.t("devise.failure.invalid", locale: :en)
      )
    end

    it "stops answering after the per-source limit (AUTH-01)" do
      Rails.cache.clear
      params = { user: { email: user.email, password: "wrong-password" } }

      11.times { post(user_session_path, params: params, as: :turbo_stream) }

      expect(response.body).to include(
        I18n.t("devise.failure.too_many_requests")
      )
    end

    it "keeps the failure generic for an unconfirmed account" do
      user.update!(confirmed_at: nil)

      post user_session_path,
           params: { user: { email: user.email, password: password } },
           as: :turbo_stream

      expect(flash[:alert]).to eq(I18n.t("devise.failure.invalid"))
    end

    it "keeps it generic on the html path too" do
      user.update!(confirmed_at: nil)

      post user_session_path, params: {
        user: { email: user.email, password: password }
      }

      expect(flash[:alert]).to eq(I18n.t("devise.failure.invalid"))
    end

    it "does not warn about the last attempt before lockout" do
      user.update!(failed_attempts: user.class.maximum_attempts - 2)

      post user_session_path,
           params: { user: { email: user.email, password: "wrong-password" } },
           as: :turbo_stream

      expect(response.body).to include(I18n.t("devise.failure.invalid"))
      expect(response.body).not_to include(I18n.t("devise.failure.last_attempt"))
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
