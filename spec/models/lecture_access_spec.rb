require "rails_helper"

RSpec.describe(Lecture) do
  let(:student) { create(:confirmed_user) }
  let(:open_lecture) { create(:lecture, :released_for_all) }
  let(:locked_lecture) { create(:lecture, :released_for_all, passphrase: "open sesame") }
  let(:unpublished) { create(:lecture) }

  describe "#unlocked_for? and User#unlocked_lectures" do
    it "agree on an open, a locked and an unlocked lecture" do
      unlocked = create(:lecture, :released_for_all, passphrase: "open sesame")
      student.bookmark_lecture!(unlocked)

      expect(open_lecture.unlocked_for?(student)).to be(true)
      expect(locked_lecture.unlocked_for?(student)).to be(false)
      expect(unlocked.unlocked_for?(student)).to be(true)
      expect(student.unlocked_lectures).to include(open_lecture, unlocked)
      expect(student.unlocked_lectures).not_to include(locked_lecture)
    end
  end

  describe "#content_accessible_by?" do
    it "lets a student into a published open lecture only" do
      expect(open_lecture.content_accessible_by?(student)).to be(true)
      expect(locked_lecture.content_accessible_by?(student)).to be(false)
      expect(unpublished.content_accessible_by?(student)).to be(false)
    end

    it "lets the lecture's editors in, whatever it is" do
      expect(locked_lecture.content_accessible_by?(locked_lecture.teacher)).to be(true)
      expect(unpublished.content_accessible_by?(unpublished.teacher)).to be(true)
    end
  end

  describe "User#unlock_lecture!" do
    it "bookmarks an open lecture" do
      expect(student.unlock_lecture!(open_lecture)).to be(true)
      expect(student.lectures).to include(open_lecture)
    end

    it "bookmarks a locked lecture with its pass phrase only" do
      expect(student.unlock_lecture!(locked_lecture, passphrase: "wrong")).to be(false)
      expect(student.unlock_lecture!(locked_lecture, passphrase: "open sesame")).to be(true)
      expect(student.lectures).to include(locked_lecture)
    end

    it "lets a member of the lecture's roster in without the pass phrase" do
      locked_lecture.add_user_to_roster!(student)

      expect(student.unlock_lecture!(locked_lecture)).to be(true)
    end

    it "refuses an unpublished lecture, pass phrase or not" do
      unpublished.update!(passphrase: "open sesame")

      expect(student.unlock_lecture!(unpublished, passphrase: "open sesame")).to be(false)
    end
  end

  describe "#bookmarkable_by?" do
    it "needs no passphrase for an open lecture" do
      expect(open_lecture.bookmarkable_by?(student)).to be(true)
    end

    it "needs the passphrase for a locked lecture" do
      expect(locked_lecture.bookmarkable_by?(student)).to be(false)
    end

    it "needs no passphrase from a member of the lecture's roster" do
      locked_lecture.add_user_to_roster!(student)

      expect(locked_lecture.bookmarkable_by?(student)).to be(true)
    end

    it "is refused for an unpublished lecture" do
      expect(unpublished.bookmarkable_by?(student)).to be(false)
    end
  end
end
