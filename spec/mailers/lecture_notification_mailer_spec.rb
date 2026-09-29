require "rails_helper"

RSpec.describe(LectureNotificationMailer, type: :mailer) do
  describe "new_tutor_email" do
    let(:tutorial) { create(:tutorial, title: "Mo 10") }
    let(:tutor) { create(:confirmed_user_en) }

    it "tells the new tutor which group and leads to it" do
      mail = described_class.with(recipient: tutor, locale: "en", tutorial: tutorial)
                            .new_tutor_email

      expect(mail.to).to eq([tutor.email])
      expect(mail.subject).to include("Mo 10", tutorial.lecture.title_for_viewers)
      expect(mail.text_part.body.decoded)
        .to include(lecture_tutorials_url(tutorial.lecture, tutorial: tutorial.id))
    end
  end
end
