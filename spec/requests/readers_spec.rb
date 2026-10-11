require "rails_helper"

RSpec.describe("Readers", type: :request) do
  let(:user) { create(:confirmed_user, unread_comments: true) }
  let(:other) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:elsewhere) { create(:lecture, :released_for_all) }

  def commented_medium(lecture)
    medium = create(:lecture_medium, teachable: lecture, released: "all",
                                     released_at: Time.zone.now)
    Commontator::Comment.create!(thread: medium.commontator_thread, creator: other,
                                 body: Faker::Lorem.sentence)
    medium
  end

  before do
    user.bookmark_lecture!(lecture)
    user.bookmark_lecture!(elsewhere)
    sign_in user
  end

  describe "PATCH /readers/update_all" do
    it "marks only the lecture's threads as read when filtered to a lecture" do
      here = commented_medium(lecture)
      commented_medium(elsewhere)

      patch update_all_readers_path(lecture_id: lecture.id), xhr: true

      expect(Reader.where(user: user).pluck(:thread_id))
        .to contain_exactly(here.commontator_thread.id)
      expect(user.reload.unread_comments).to be(true)
    end

    it "marks every thread as read without a filter" do
      commented_medium(lecture)
      commented_medium(elsewhere)

      patch update_all_readers_path, xhr: true

      expect(Reader.where(user: user).count).to eq(2)
      expect(user.reload.unread_comments).to be(false)
    end
  end
end
