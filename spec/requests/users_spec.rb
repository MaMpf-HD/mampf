require "rails_helper"

RSpec.describe("Users administration", type: :request) do
  describe "GET /users" do
    it "shows the password policy progress summary for admins" do
      admin = create(:confirmed_user, admin: true)
      create(:confirmed_user)
      stale_user = create(:confirmed_user)
      # rubocop:disable Rails/SkipsModelValidations
      stale_user.update_columns(password_policy_version: 0,
                                password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations

      sign_in admin

      get users_path

      expect(response).to have_http_status(:ok)
      expected_current_count = 2
      expected_total_count = 3

      expect(response.body)
        .to include(I18n.t("admin.user.password_policy_progress",
                           current: expected_current_count,
                           total: expected_total_count))
    end
  end
end
