require "rails_helper"

RSpec.describe("Notifications", type: :request) do
  let(:user) { create(:confirmed_user) }

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
