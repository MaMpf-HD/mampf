require "rails_helper"

RSpec.describe(LectureNotificationMailer, type: :mailer) do
  describe "new_tutor_email" do
    let(:lecture) { create(:lecture) }
    let(:tutor) { create(:confirmed_user_en) }

    it "tells the new tutor in which lecture" do
      mail = described_class.with(recipient: tutor, locale: "en", lecture: lecture)
                            .new_tutor_email

      expect(mail.to).to eq([tutor.email])
      expect(mail.subject).to include(lecture.title_for_viewers)
      expect(mail.text_part.body.decoded).to include(root_url)
    end
  end
end
