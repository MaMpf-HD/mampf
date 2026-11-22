require "rails_helper"

RSpec.describe("Notifications", type: :request) do
  let(:user) { create(:confirmed_user) }

  describe "GET /notifications" do
    it "names the user who redeemed a voucher as the text that was typed" do
      lecture = create(:lecture, teacher: user)
      redeemer = create(:confirmed_user,
                        name: 'Ada <b class="big" name="title">Lovelace</b> ' \
                              '<img src="x.png">')
      redemption = Redemption.create!(
        user: redeemer, voucher: create(:voucher, :editor, lecture: lecture)
      )
      create(:notification, recipient: user, notifiable: redemption)
      sign_in user

      get notifications_path

      card = Nokogiri::HTML(response.body).at_css(".bg-post-it-green")
      expect(card.at_css(".card-body").text).to include(redeemer.info)
      expect(card.css(".card-body b, .card-body img, [name]")).to be_empty
      people_tab = edit_lecture_path(lecture, anchor: "people")
      expect(card.at_css(".card-header a.text-dark[href='#{people_tab}']").text)
        .to eq(lecture.title_for_viewers)
    end
  end

  describe "POST /notifications/destroy_lecture_media_notifications" do
    it "marks the lecture's new media as seen and leaves everything else" do
      lesson = create(:valid_lesson)
      lecture = lesson.lecture
      medium = create(:lesson_medium, :released, teachable: lesson)
      seen = create(:notification, recipient: user, notifiable: medium)
      other_lecture_medium = create(:lesson_medium, :released)
      kept = create(:notification, recipient: user, notifiable: other_lecture_medium)
      someone_elses = create(:notification, recipient: create(:confirmed_user),
                                            notifiable: medium)
      sign_in user

      post destroy_lecture_media_notifications_path(lecture_id: lecture.id),
           as: :turbo_stream

      expect(Notification.exists?(seen.id)).to be(false)
      expect(Notification.exists?(kept.id)).to be(true)
      expect(Notification.exists?(someone_elses.id)).to be(true)
      assert_turbo_stream action: :remove, target: "lecture-home-new-media"
    end
  end
end
