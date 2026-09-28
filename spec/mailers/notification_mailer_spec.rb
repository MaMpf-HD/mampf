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

  describe "new_lecture_email" do
    let(:recipient) { create(:confirmed_user) }
    let(:lecture) { create(:lecture) }

    it "has its button lead to the dashboard's lecture search" do
      mail = NotificationMailer.with(recipients: [recipient.id],
                                     lecture: lecture).new_lecture_email
      button = Nokogiri::HTML(mail.html_part.body.decoded).at_css("a.btn")
      expect(button["href"]).to eq(root_url(anchor: "lecture-search"))
    end
  end
end
