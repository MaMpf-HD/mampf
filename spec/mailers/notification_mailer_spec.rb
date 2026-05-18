require "rails_helper"

RSpec.describe(NotificationMailer, type: :mailer) do
  describe "announcement_email" do
    let(:user) { create(:user) }
    let(:teacher) { create(:confirmed_user) }
    let(:announcement) do
      create(:announcement, announcer: teacher, details: "<script>alert('xss-in-email')</script>")
    end

    it "escapes or strips script tags in the email body" do
      mail = NotificationMailer.with(recipient: user, announcement: announcement).announcement_email
      expect(mail.body.encoded).not_to include("<script>alert('xss-in-email')</script>")
    end
  end
end
