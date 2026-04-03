require "rails_helper"

RSpec.describe(RosterParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:group_type) { :all }
  let(:participants) { lecture.lecture_memberships }
  let(:pagy) { nil }
  let(:filter_mode) { "all" }
  let(:component) do
    lecture.reload
    described_class.new(lecture: lecture, group_type: group_type,
                        participants: participants, pagy: pagy, filter_mode: filter_mode)
  end

  describe "#participants" do
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| create(:lecture_membership, lecture: lecture, user: u) }
    end

    it "returns the lecture memberships" do
      expect(component.participants.size).to eq(3)
    end
  end

  describe "filtering behavior" do
    let(:user_assigned) { create(:user) }
    let(:user_unassigned) { create(:user) }
    let!(:tutorial) { create(:tutorial, lecture: lecture) }

    before do
      create(:lecture_membership, lecture: lecture, user: user_assigned)
      create(:lecture_membership, lecture: lecture, user: user_unassigned)
      create(:tutorial_membership, tutorial: tutorial, user: user_assigned)
    end

    context "when filter_mode is 'all'" do
      let(:filter_mode) { "all" }

      it "shows all participants" do
        expect(component.filter_mode).to eq("all")
        expect(component.participants.map(&:user)).to include(user_assigned, user_unassigned)
      end
    end

    context "when filter_mode is 'unassigned'" do
      let(:filter_mode) { "unassigned" }
      let(:participants) do
        lecture.lecture_memberships.joins(:user)
               .where.not(user_id: TutorialMembership.joins(:tutorial)
                                                     .where(tutorials: { lecture_id: lecture.id })
                                                     .select(:user_id))
      end

      it "shows only unassigned participants" do
        expect(component.filter_mode).to eq("unassigned")
        expect(component.participants.map(&:user)).to include(user_unassigned)
        expect(component.participants.map(&:user)).not_to include(user_assigned)
      end
    end

    context "when pagy is provided" do
      let(:pagy) do
        double("Pagy",
               series: [1, "2", 3],
               page: 1,
               pages: 3,
               next: 2,
               prev: nil,
               vars: { page: 1, count: 100, limit: 10 })
      end

      it "enables pagination" do
        expect(component.pagy).to eq(pagy)
      end
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

  describe "#pagination_nav" do
    let(:pagy) do
      # Use a double because Pagy.new behavior is inconsistent in this environment
      double("Pagy",
             series: [1, "2", 3],
             page: 1,
             pages: 3,
             next: 2,
             prev: nil,
             vars: { page: 1, count: 100, limit: 10 },
             series_nav: "expected_html")
    end
    let(:group_type) { :tutorials }
    let(:component) do
      described_class.new(lecture: lecture, group_type: group_type, participants: participants,
                          pagy: pagy)
    end

    before do
      # Helper needs to be available for path generation
      allow_any_instance_of(RosterParticipantsComponent)
        .to receive(:helpers).and_wrap_original do |original_method, *args|
        original_method.call(*args)
      end
    end

    context "when there is only one page" do
      let(:pagy) { double("Pagy", pages: 1) }

      it "returns nil" do
        # Ensure we don't try to render pagy
        render_inline(component)
        expect(component.pagination_nav).to be_nil
        expect(rendered_content).not_to include("pagy-series-nav")
      end
    end

    context "when pagy is nil" do
      let(:pagy) { nil }

      it "returns nil" do
        render_inline(component)
        expect(component.pagination_nav).to be_nil
        expect(rendered_content).not_to include("pagy-series-nav")
      end
    end
  end
end
