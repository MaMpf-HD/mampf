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

    # The dashboard's search shows the term picked there, not the lecture's.
    it "names the lecture's term in both parts" do
      mail = NotificationMailer.with(recipients: [recipient.id],
                                     lecture: lecture).new_lecture_email

      expect(mail.html_part.body.decoded).to include(lecture.term.to_label)
      expect(mail.text_part.body.decoded).to include(lecture.term.to_label)
    end

    it "names no term for a lecture without one" do
      lecture = create(:lecture, :term_independent)
      mail = NotificationMailer.with(recipients: [recipient.id], lecture: lecture,
                                     locale: :en).new_lecture_email

      expect(mail.text_part.body.decoded)
        .to include(I18n.t("mailer.subscribe_lecture_text", locale: :en).strip)
    end
  end

  describe "submission_removed_email" do
    let(:removed) { create(:confirmed_user, name_in_tutorials: "Grace Hopper") }
    let(:tutor) { create(:confirmed_user, name_in_tutorials: "Alan Turing") }
    let(:team) do
      create(:valid_submission,
             users: [create(:confirmed_user, name_in_tutorials: "Ada Lovelace")])
    end

    it "names the tutor and the team the recipient is no longer on" do
      mail = NotificationMailer.with(recipient: removed, locale: :en, submission: team,
                                     user: tutor).submission_removed_email
      body = mail.html_part.body.decoded

      expect(mail.to).to eq([removed.email])
      expect(body).to include("Alan Turing has taken you off the team of Ada Lovelace")
      expect(body).not_to include("Grace Hopper")
    end
  end
end
