require "rails_helper"

RSpec.describe("Auth passwords", type: :request) do
  before do
    ActionMailer::Base.deliveries.clear
  end

  let(:new_password) { "super-secure-horse-battery-staple" }

  describe "POST /users/password" do
    it "sends reset instructions for an existing user" do
      user = create(:confirmed_user_en)

      expect do
        post(user_password_path, params: { user: { email: user.email } })
      end.to change(ActionMailer::Base.deliveries, :count).by(1)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "stops sending reset emails after the per-source limit (AUTH-H02)" do
      Rails.cache.clear
      user = create(:confirmed_user_en)
      ActionMailer::Base.deliveries.clear

      params = { user: { email: user.email } }
      6.times { post(user_password_path, params: params) }

      expect(ActionMailer::Base.deliveries.count).to eq(5)
    end

    it "does not send mail for an unknown email in paranoid mode" do
      expect do
        post(user_password_path, params: { user: { email: "unknown@example.com" } })
      end.not_to change(ActionMailer::Base.deliveries, :count)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /users/password/restart" do
    it "signs out stale users and redirects them to the reset form" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      sign_in user

      post restart_user_password_path(locale: :de)

      expect(response).to redirect_to(new_user_password_path(locale: :de))

      follow_redirect!

      expect(response).to have_http_status(:ok)

      get edit_user_registration_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PUT /users/password with a weak password" do
    it "refuses it on the reset path too", :password_strength do
      user = create(:confirmed_user_en)
      post user_password_path, params: { user: { email: user.email } }
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :reset_password_token)
      weak = "Sommersemester2026"

      put user_password_path, params: {
        user: { reset_password_token: token, password: weak,
                password_confirmation: weak }
      }

      expect(response.body).to include(I18n.t("errors.messages.password_too_weak"))
      expect(user.reload.valid_password?(weak)).to be(false)
    end
  end

  describe "PUT /users/password with the password the account already has" do
    it "refuses it while a change is due" do
      password = "zitrone-diskette-vorhang-42"
      user = create(:confirmed_user_en, password: password)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
      post user_password_path, params: { user: { email: user.email } }
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :reset_password_token)

      put user_password_path, params: {
        user: { reset_password_token: token, password: password,
                password_confirmation: password }
      }

      expect(response.body).to include(I18n.t("errors.messages.password_unchanged"))
      expect(user.reload).to be_password_change_required
    end
  end

  describe "the language switch" do
    def switch_target
      response.body[%r{<div id="language-switch".*?</div>}m]
              .to_s[/href="([^"]*)"/, 1]
    end

    it "points at the form, not at the path the form posts to" do
      put user_password_path, params: {
        user: { reset_password_token: "not-a-real-token",
                password: "too-short", password_confirmation: "too-short" }
      }

      expect(switch_target)
        .to include(edit_user_password_path, "reset_password_token=not-a-real-token")
    end

    it "does not choke on a crafted user parameter" do
      get edit_user_password_path(reset_password_token: "abc", user: "not-a-hash")

      expect(response).to have_http_status(:ok)
      expect(switch_target).to include("reset_password_token=abc")
    end
  end

  describe "PUT /users/password" do
    it "updates the password from a valid reset token" do
      user = create(:confirmed_user_en)
      # rubocop:disable Rails/SkipsModelValidations
      user.update_columns(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations

      post user_password_path, params: { user: { email: user.email } }
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :reset_password_token)

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: new_password,
          password_confirmation: new_password
        }
      }

      # the reset signs the user in, and this is their first sign-in
      expect(response).to redirect_to(edit_profile_path)
      expect(user.reload.password_policy_version)
        .to eq(User::CURRENT_PASSWORD_POLICY_VERSION)
      expect(user.password_changed_at).to be_present

      delete destroy_user_session_path
      post user_session_path,
           params: { user: { email: user.email, password: new_password } }

      expect(response).to redirect_to(start_path)
    end

    it "rejects an invalid reset token" do
      user = create(:confirmed_user_en)

      put user_password_path, params: {
        user: {
          reset_password_token: "invalid-token",
          password: new_password,
          password_confirmation: new_password
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("devise.passwords.edit.change_password"))
      expect(user.valid_password?(new_password)).to be(false)
    end
  end
end
