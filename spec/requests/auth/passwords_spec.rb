require "rails_helper"

RSpec.describe("Auth passwords", type: :request) do
  around do |example|
    Current.password_strength_validation_enabled = true
    example.run
  ensure
    Current.reset
  end

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

      expect(response).to redirect_to(start_path)
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
