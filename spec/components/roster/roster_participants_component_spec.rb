require "rails_helper"

RSpec.describe(RosterParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:group_type) { :all }
  let(:component) { described_class.new(lecture: lecture, group_type: group_type) }

  describe "#participants" do
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| create(:lecture_membership, lecture: lecture, user: u) }
    end

    it "returns the lecture memberships" do
      expect(component.participants.size).to eq(3)
    end
  end

  describe "#participant_status" do
    let(:user) { create(:user) }
    let!(:membership) { create(:lecture_membership, lecture: lecture, user: user) }

    context "when user is not in any group" do
      it "returns :unassigned" do
        expect(component.participant_status(user)).to eq(:unassigned)
      end
    end

    context "when user is in a tutorial" do
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:tutorial_membership) { create(:tutorial_membership, tutorial: tutorial, user: user) }

      it "returns :assigned" do
        expect(component.participant_status(user)).to eq(:assigned)
      end
    end

    context "when user is in a cohort only" do
      let(:cohort) { create(:cohort, context: lecture) }
      let!(:cohort_membership) { create(:cohort_membership, cohort: cohort, user: user) }

      it "returns :unassigned" do
        expect(component.participant_status(user)).to eq(:unassigned)
      end
    end
  end

  describe "#assigned_participants" do
    let(:user_assigned) { create(:user) }
    let(:user_unassigned) { create(:user) }
    let!(:tutorial) { create(:tutorial, lecture: lecture) }

    before do
      create(:lecture_membership, lecture: lecture, user: user_assigned)
      create(:lecture_membership, lecture: lecture, user: user_unassigned)
      create(:tutorial_membership, tutorial: tutorial, user: user_assigned)
    end

    it "returns only assigned participants" do
      expect(component.assigned_participants.map(&:user)).to include(user_assigned)
      expect(component.assigned_participants.map(&:user)).not_to include(user_unassigned)
    end
  end

  describe "#unassigned_participants" do
    let(:user_assigned) { create(:user) }
    let(:user_unassigned) { create(:user) }
    let!(:tutorial) { create(:tutorial, lecture: lecture) }

    before do
      create(:lecture_membership, lecture: lecture, user: user_assigned)
      create(:lecture_membership, lecture: lecture, user: user_unassigned)
      create(:tutorial_membership, tutorial: tutorial, user: user_assigned)
    end

    it "returns only unassigned participants" do
      expect(component.unassigned_participants.map(&:user)).to include(user_unassigned)
      expect(component.unassigned_participants.map(&:user)).not_to include(user_assigned)
    end
  end

  describe "#group_path" do
    let(:helpers) { double("helpers") }

    before do
      allow(component).to receive(:helpers).and_return(helpers)
    end

    it "returns tutorial roster path for a Tutorial" do
      tutorial = create(:tutorial, lecture: lecture)
      allow(helpers).to receive(:tutorial_roster_path)
        .with(tutorial).and_return("/tutorials/#{tutorial.id}/roster")
      expect(component.group_path(tutorial)).to eq("/tutorials/#{tutorial.id}/roster")
    end
  end
end
