require "rails_helper"

RSpec.describe("Auth unlocks", type: :request) do
  describe "GET /users/unlock" do
    it "unlocks the account through the link from the mail" do
      user = create(:confirmed_user_en, password: "Password123!")
      ActionMailer::Base.deliveries.clear
      user.lock_access!
      token = devise_mail_token(ActionMailer::Base.deliveries.last,
                                :unlock_token)

      get user_unlock_path(unlock_token: token, locale: "en")

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload).not_to be_access_locked
    end

    it "rejects a token that does not belong to anyone" do
      user = create(:confirmed_user_en, password: "Password123!")
      user.lock_access!

      get user_unlock_path(unlock_token: "not-a-token", locale: "en")

      expect(user.reload).to be_access_locked
    end
  end
end
