require "rails_helper"

RSpec.describe(TutorialMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:tutorial_membership)).to be_valid
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
  end
end
