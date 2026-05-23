require "rails_helper"

RSpec.describe("Users administration", type: :request) do
  describe "GET /users" do
    it "shows the password policy progress summary for admins" do
      admin = create(:confirmed_user, admin: true)
      create(:confirmed_user)
      stale_user = create(:confirmed_user)
      stale_user.update_columns(password_policy_version: 0,
                                password_changed_at: nil)

      sign_in admin

      get users_path

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include(I18n.t("admin.user.password_policy_progress",
                           current: User.confirmed.where(
                             "password_policy_version >= ?",
                             User::CURRENT_PASSWORD_POLICY_VERSION
                           ).count,
                           total: User.confirmed.count))
    end
  end
end
