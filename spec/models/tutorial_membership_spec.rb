require "rails_helper"

RSpec.describe(TutorialMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:tutorial_membership)).to be_valid
  end

  describe "associations" do
    it "populates lecture_id automatically from the tutorial" do
      tutorial = create(:tutorial)
      membership = build(:tutorial_membership, tutorial: tutorial)
      membership.valid?

      expect(membership.lecture_id).to eq(tutorial.lecture_id)
    end
  end

  describe "validations" do
    describe "#unique_membership_per_lecture" do
      let(:lecture) { create(:lecture) }
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:other_tutorial) { create(:tutorial, lecture: lecture) }
      let(:user) { create(:user) }

      it "allows joining a tutorial if not in any other tutorial of the lecture" do
        membership = build(:tutorial_membership, user: user, tutorial: tutorial)
        expect(membership).to be_valid
      end

      it "prevents joining a second tutorial in the same lecture" do
        create(:tutorial_membership, user: user, tutorial: tutorial)
        membership = build(:tutorial_membership, user: user, tutorial: other_tutorial)

        expect(membership).to be_invalid
        expect(membership.errors.added?(:base, :already_in_lecture_tutorial)).to be(true)
      end

      it "allows joining a tutorial in a different lecture" do
        other_lecture = create(:lecture)
        other_lecture_tutorial = create(:tutorial, lecture: other_lecture)
        create(:tutorial_membership, user: user, tutorial: other_lecture_tutorial)

        membership = build(:tutorial_membership, user: user, tutorial: tutorial)
        expect(membership).to be_valid
      end

      it "allows updating an existing membership" do
        membership = create(:tutorial_membership, user: user, tutorial: tutorial)
        expect(membership).to be_valid
      end
    end

    describe "#lecture_matches_tutorial" do
      it "is invalid when lecture_id is overridden to a mismatching lecture" do
        other_lecture = create(:lecture)
        tutorial = create(:tutorial)
        membership = build(:tutorial_membership, tutorial: tutorial)
        membership.lecture_id = other_lecture.id

        expect(membership).to be_invalid
        expect(membership.errors.added?(:lecture, :does_not_match_tutorial)).to be(true)
      end
    end
  end
end
