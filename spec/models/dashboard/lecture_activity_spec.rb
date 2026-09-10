require "rails_helper"

RSpec.describe(Dashboard::LectureActivity) do
  let(:user) { create(:confirmed_user) }
  let(:other) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:digest) { described_class.new(user: user, lectures: [lecture]) }

  def commented_medium(creator:, teachable: lecture, released: "all")
    medium = create(:lecture_medium, teachable: teachable, released: released,
                                     released_at: Time.zone.now)
    Commontator::Comment.create!(thread: medium.commontator_thread,
                                 creator: creator,
                                 body: Faker::Lorem.sentence)
    medium
  end

  describe "#unread_comments" do
    it "counts what somebody else wrote and the user has not opened" do
      commented_medium(creator: other)

      expect(digest.unread_comments(lecture)).to eq(1)
    end

    it "ignores the user's own comments" do
      commented_medium(creator: user)

      expect(digest.unread_comments(lecture)).to eq(0)
    end

    it "ignores a thread the user has opened since the comment" do
      medium = commented_medium(creator: other)
      Reader.create!(user: user, thread: medium.commontator_thread,
                     updated_at: 1.minute.from_now)

      expect(digest.unread_comments(lecture)).to eq(0)
    end

    it "ignores media that are not out yet" do
      commented_medium(creator: other, released: nil)

      expect(digest.unread_comments(lecture)).to eq(0)
    end

    it "ignores lectures that are not on the board" do
      other_lecture = create(:lecture, :released_for_all)
      commented_medium(creator: other, teachable: other_lecture)

      expect(digest.unread_comments(other_lecture)).to eq(0)
    end
  end

  describe "#any?" do
    it "is false for a quiet lecture" do
      expect(digest).not_to be_any(lecture)
    end

    it "is true as soon as there is something unread" do
      commented_medium(creator: other)

      expect(digest).to be_any(lecture)
    end
  end
end
