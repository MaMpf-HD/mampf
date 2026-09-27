require "rails_helper"

RSpec.describe("Auth unlocks", type: :request) do
  describe "POST /users/unlock (resend)" do
    it "stops sending unlock emails after the per-source limit (AUTH-H02)" do
      Rails.cache.clear
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      user.lock_access!
      ActionMailer::Base.deliveries.clear # drop the mail sent on locking

      params = { user: { email: user.email } }
      6.times { post(user_unlock_path, params: params) }

      expect(ActionMailer::Base.deliveries.count).to eq(5)
    end

    it "stops sending unlock emails to one address after the daily limit" do
      Rails.cache.clear
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      user.lock_access!
      ActionMailer::Base.deliveries.clear # drop the mail sent on locking

      params = { user: { email: user.email }, locale: "en" }
      11.times do |i|
        post(user_unlock_path, params: params, env: { "REMOTE_ADDR" => "10.0.0.#{i}" })
      end

      expect(ActionMailer::Base.deliveries.count).to eq(10)
      expect(flash[:alert]).to eq(
        I18n.t("devise.failure.too_many_requests", wait: "1 day", locale: :en)
      )
    end
  end

  describe "GET /users/unlock" do
    it "unlocks the account through the link from the mail" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      ActionMailer::Base.deliveries.clear
      user.lock_access!
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :unlock_token)

      get user_unlock_path(unlock_token: token, locale: "en")

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload).not_to be_access_locked
    end

    it "rejects a token that does not belong to anyone" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      user.lock_access!

      get user_unlock_path(unlock_token: "not-a-token", locale: "en")

      expect(user.reload).to be_access_locked
    end
  end
end
