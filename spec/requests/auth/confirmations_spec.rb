require "rails_helper"

RSpec.describe("Auth confirmations", type: :request) do
  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "GET /users/confirmation" do
    it "confirms a user and signs them in" do
      user = create(:user, locale: "en", consents: true,
                           consented_at: Time.zone.now)
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :confirmation_token)

      get user_confirmation_path,
          params: { confirmation_token: token, locale: "en" }

      expect(response).to redirect_to(edit_profile_path)
      expect(user.reload).to be_confirmed

      get edit_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "rejects an invalid token" do
      get user_confirmation_path,
          params: { confirmation_token: "invalid-token", locale: "en" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        I18n.t("devise.confirmations.new.resend_confirmation_instructions")
      )
    end

    it "applies a reconfirmed email change" do
      user = create(:confirmed_user_en)
      new_email = "updated_#{SecureRandom.hex(4)}@example.com"

      sign_in user

      put user_registration_path, params: {
        user: {
          email: new_email,
          current_password: user.password,
          password: "",
          password_confirmation: ""
        }
      }

      expect(user.reload.email).not_to eq(new_email)
      expect(user.unconfirmed_email).to eq(new_email)

      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :confirmation_token)

      get user_confirmation_path,
          params: { confirmation_token: token, locale: "en" }

      expect(response).to redirect_to(edit_profile_path)
      expect(user.reload.email).to eq(new_email)
      expect(user.unconfirmed_email).to be_nil
    end
  end

  describe "POST /users/confirmation (resend)" do
    it "stops sending confirmation emails after the per-source limit (AUTH-H02)" do
      Rails.cache.clear
      user = create(:user) # unconfirmed
      ActionMailer::Base.deliveries.clear # drop the sign-up confirmation mail

      params = { user: { email: user.email } }
      6.times { post(user_confirmation_path, params: params) }

      # rate_limit allows 5 within the hour; the 6th request is throttled before
      # the action runs, so no 6th mail goes out.
      expect(ActionMailer::Base.deliveries.count).to eq(5)
    end
  end
end
