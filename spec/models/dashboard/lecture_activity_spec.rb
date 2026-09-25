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

    it "counts each comment, not each medium" do
      medium = commented_medium(creator: other)
      Commontator::Comment.create!(thread: medium.commontator_thread, creator: other,
                                   body: Faker::Lorem.sentence)

      expect(digest.unread_comments(lecture)).to eq(2)
    end

    it "counts comments on the lecture's lessons too" do
      medium = create(:lesson_medium)
      medium.teachable.lecture.update!(released: "all")
      medium.update!(released: "all", released_at: Time.zone.now)
      Commontator::Comment.create!(thread: medium.commontator_thread, creator: other,
                                   body: Faker::Lorem.sentence)
      lesson_lecture = medium.teachable.lecture
      lesson_digest = described_class.new(user: user, lectures: [lesson_lecture])

      expect(lesson_digest.unread_comments(lesson_lecture)).to eq(1)
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

  describe "#unread_forum_topics" do
    it "is zero for a lecture without a forum" do
      expect(digest.unread_forum_topics(lecture)).to eq(0)
    end

    it "matches Lecture#unread_forum_topics_count" do
      board = Thredded::Messageboard.create!(name: "Forum #{lecture.id}")
      lecture.update!(forum_id: board.id)
      Thredded::Topic.create!(messageboard: board, user: other,
                              last_user: other, title: "Question")

      expect(digest.unread_forum_topics(lecture))
        .to eq(lecture.unread_forum_topics_count(user))
    end
  end

  describe "#registration_status" do
    it "matches Lecture#registration_status_for" do
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: user, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      expect(digest.registration_status(lecture)).to eq(:pending)
    end

    it "is nil for a lecture without registration" do
      expect(digest.registration_status(lecture)).to be_nil
    end
  end

  describe "#card_style" do
    it "finds the user's style for the lecture" do
      style = Dashboard::CardStyle.create!(user: user, lecture: lecture,
                                           tape_color: "mint")

      expect(digest.card_style(lecture)).to eq(style)
    end

    it "ignores other users' styles" do
      Dashboard::CardStyle.create!(user: other, lecture: lecture,
                                   tape_color: "mint")

      expect(digest.card_style(lecture)).to be_nil
    end
  end
end
