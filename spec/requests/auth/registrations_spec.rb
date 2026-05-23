require "rails_helper"

RSpec.describe("Auth registrations", type: :request) do
  around do |example|
    Current.password_strength_validation_enabled = true
    example.run
  ensure
    Current.reset
  end

  before do
    ActionMailer::Base.deliveries.clear
  end

  describe "POST /users" do
    let(:email) { "signup_#{SecureRandom.hex(4)}@example.com" }
    let(:base_params) do
      {
        user: {
          email: email,
          password: "super-secure-horse-battery-staple",
          password_confirmation: "super-secure-horse-battery-staple",
          consents: "1",
          locale: "en"
        }
      }
    end

    it "creates an unconfirmed user when captcha validation succeeds" do
      allow(AltchaSolution).to receive(:verify_and_save).and_return(true)

      expect do
        post(user_registration_path, params: base_params.merge(altcha: "valid"))
      end.to change(User, :count).by(1)

      created_user = User.order(:id).last
      expect(created_user.email).to eq(email)
      expect(created_user).not_to be_confirmed
      expect(ActionMailer::Base.deliveries.last.to).to include(email)
    end

    it "does not create a user when captcha validation fails" do
      allow(AltchaSolution).to receive(:verify_and_save).and_return(false)

      expect do
        post(user_registration_path,
             params: base_params.merge(altcha: "invalid"),
             as: :turbo_stream)
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(I18n.t("devise.registrations.user.captcha_error"))
    end

    it "blocks sign up when the registration limit is exceeded" do
      allow(AltchaSolution).to receive(:verify_and_save).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MAMPF_REGISTRATION_TIMEFRAME", 15).and_return("15")
      allow(ENV).to receive(:fetch).with("MAMPF_MAX_REGISTRATION_PER_TIMEFRAME", 40).and_return("0")
      create(:user, created_at: 1.minute.ago)

      expect do
        post(user_registration_path, params: base_params.merge(altcha: "valid"))
      end.not_to change(User, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("devise.registrations.user.too_many_registrations"))
    end
  end

  describe "DELETE /users" do
    it "deletes the account when the password is correct" do
      user = create(:confirmed_user_en)
      sign_in user

      expect do
        delete(user_registration_path, params: { password: user.password })
      end.to change(User, :count).by(-1)

      expect(response).to redirect_to(root_path)

      get edit_profile_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "keeps the account when the password is incorrect" do
      user = create(:confirmed_user_en)
      sign_in user

      expect do
        delete(user_registration_path, params: { password: "wrong-password" })
      end.not_to change(User, :count)

      expect(response).to redirect_to(edit_profile_path)
      expect(user.reload).to be_present
    end
  end

  describe "PUT /users" do
    it "stores a pending email change for reconfirmation" do
      user = create(:confirmed_user_en)
      new_email = "pending_#{SecureRandom.hex(4)}@example.com"

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
      expect(ActionMailer::Base.deliveries.last.to).to include(new_email)
    end
  end

  describe "GET /users/edit" do
    it "renders stable back and language switch links" do
      user = create(:confirmed_user_en)
      sign_in user

      get edit_user_registration_path(locale: :en)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(edit_profile_path)
      expect(response.body).to include(edit_user_registration_path(locale: :de))
    end

    it "switches locale for signed-in users when a locale param is provided" do
      user = create(:confirmed_user_en)
      sign_in user

      get edit_user_registration_path(locale: :de)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.with_locale(:de) { I18n.t("devise.edit.title") })
      expect(user.reload.locale).to eq("en")
    end
  end
end
