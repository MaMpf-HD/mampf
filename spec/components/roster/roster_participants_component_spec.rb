require "rails_helper"

RSpec.describe(RosterParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:group_type) { :all }
  # Mock participants passing
  let(:participants) { lecture.lecture_memberships }
  let(:component) do
    described_class.new(lecture: lecture, group_type: group_type, participants: participants)
  end

  describe "#participants" do
    let!(:users) { create_list(:user, 3) }

    before do
      users.each { |u| create(:lecture_membership, lecture: lecture, user: u) }
    end

    it "returns the lecture memberships" do
      # Refresh participants relation
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

  describe "pagination" do
    let(:pagy) do
      # Use a double because Pagy.new behavior is inconsistent in this environment
      double("Pagy",
             series: [1, "2", 3],
             page: 1,
             pages: 3,
             next: 2,
             prev: nil,
             vars: { page: 1, count: 100, limit: 10 },
             series_nav: "expected_html") # Mock the series_nav method called by helper
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

    it "renders pagination links with preserved params" do
      # Verify that the component calls series_nav with the correct querify logic
      expect(pagy).to receive(:series_nav).at_least(:once) do |_style, **kwargs|
        querify = kwargs[:querify]
        expect(querify).to be_a(Proc)

        # Test the lambda logic: it should inject our params into the hash
        params = {}
        querify.call(params)
        expect(params["tab"]).to eq("participants")
        expect(params["group_type"]).to eq("tutorials")

        "mocked_pagination_html"
      end

      html = render_inline(component).to_html

      # The rendered output should include our mocked return value
      expect(html).to include("mocked_pagination_html")
    end
  end
end
