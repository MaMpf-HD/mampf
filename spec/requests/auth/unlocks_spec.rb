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

  describe "POST /users/unlock for an account that is not locked" do
    before do
      Rails.cache.clear
      ActionMailer::Base.deliveries.clear
    end

    it "sends the password reset mail, since the password is what is missing" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      ActionMailer::Base.deliveries.clear

      post(user_unlock_path, params: { user: { email: user.email }, locale: "en" })

      mail = ActionMailer::Base.deliveries.sole
      expect(mail.to).to eq([user.email])
      expect(mail.subject).to eq(I18n.t("devise.mailer.reset_password_instructions.subject",
                                        locale: :en))
      expect(user.reload.reset_password_sent_at).to be_present
    end

    it "does the same once a lock has run out" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      user.lock_access!
      user.update!(locked_at: (Devise.unlock_in + 1.minute).ago)
      ActionMailer::Base.deliveries.clear

      post(user_unlock_path, params: { user: { email: user.email }, locale: "en" })

      expect(ActionMailer::Base.deliveries.sole.subject)
        .to eq(I18n.t("devise.mailer.reset_password_instructions.subject", locale: :en))
    end

    it "answers as for any address and sends nothing for an unknown one" do
      post(user_unlock_path, params: { user: { email: "nobody@example.com" }, locale: "en" })

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(flash[:notice])
        .to eq(I18n.t("devise.unlocks.send_paranoid_instructions", locale: :en))
    end
  end

  describe "the mail sent on locking" do
    it "points to the password reset as well" do
      user = create(:confirmed_user_en, password: "correct-horse-battery-staple")
      ActionMailer::Base.deliveries.clear

      user.lock_access!

      mail = ActionMailer::Base.deliveries.sole
      links = Nokogiri::HTML((mail.html_part || mail).body.decoded).css("a").pluck("href")
      expect(links).to include(a_string_including("unlock_token="),
                               a_string_including(new_user_password_path))
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
