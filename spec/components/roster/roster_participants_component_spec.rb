require "rails_helper"

RSpec.describe(RosterParticipantsComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:group_type) { :all }
  # Mock participants passing
  let(:participants) { lecture.lecture_memberships }
  let(:component) do
    # Ensure association data is fresh for the component instance
    lecture.reload
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

    context "when there are multiple pages" do
      it "returns pagination HTML with preserved params" do
        # Verify that the component calls series_nav with the correct querify logic
        expect(pagy).to receive(:series_nav).at_least(:once) do |_style, **kwargs|
          querify = kwargs[:querify]
          expect(querify).to be_a(Proc)

          # Test the lambda logic: it should inject our params into the hash
          params = {}
          querify.call(params)
          expect(params["tab"]).to eq("participants")
          expect(params["group_type"]).to eq("tutorials")
          expect(params["filter"]).to eq("all")

          "mocked_pagination_html"
        end

        # We use render_inline to ensure the component helpers are setup correctly
        html = render_inline(component).to_html
        expect(html).to include("mocked_pagination_html")
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

  describe "#available_transfer_targets_for" do
    let(:user) { create(:user) }

    context "when there are tutorials and cohorts" do
      let!(:tutorial_a) do
        create(:tutorial, lecture: lecture, title: "A Tutorial", skip_campaigns: true)
      end
      let(:tutorial2) do
        create(:tutorial, lecture: lecture, title: "B Tutorial", skip_campaigns: true)
      end
      let(:cohort) do
        create(:cohort, context: lecture, title: "A Cohort", skip_campaigns: true)
      end

      before do
        # Enroll user in lecture so they are eligible
        create(:lecture_membership, lecture: lecture, user: user)
        # We mock the group retrieval to ensure we work with the exact instances
        # created above. This isolates the test from DB/Association caching issues
        # and allows stubbing methods on instances.
        allow(component).to receive(:all_assignable_groups).and_return([tutorial_a, tutorial2,
                                                                        cohort])
      end

      it "groups and sorts correctly: Tutorials (1) then Cohorts (2)" do
        targets = component.available_transfer_targets_for(user)

        # Expect 2 groups: Tutorials and Cohorts
        expect(targets.size).to eq(2)

        # Check first group (Tutorials)
        expect(targets[0][:groups]).to match_array([tutorial_a, tutorial2])
        # Check internal sorting (A before B)
        expect(targets[0][:groups]).to eq([tutorial_a, tutorial2])

        # Check second group (Cohorts)
        expect(targets[1][:groups]).to match_array([cohort])
      end

      it "excludes locked groups" do
        locked_tut = create(:tutorial, lecture: lecture, title: "Locked Tutorial")

        # Update the mock to include the locked tutorial
        allow(component).to receive(:all_assignable_groups).and_return([tutorial_a, tutorial2,
                                                                        cohort, locked_tut])
        allow(locked_tut).to receive(:locked?).and_return(true)

        targets = component.available_transfer_targets_for(user)

        # Find the group section containing the tutorials
        tutorial_group = targets.find { |t| t[:groups].first.is_a?(Tutorial) }
        expect(tutorial_group[:groups]).not_to include(locked_tut)
        expect(tutorial_group[:groups]).to include(tutorial_a)
      end
    end

    context "when user is already in a tutorial" do
      let!(:tutorial_a) { create(:tutorial, lecture: lecture, title: "A Tutorial") }

      before do
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: tutorial_a, user: user)
        # Mocking to resolve any association/caching issues
        allow(component).to receive(:all_assignable_groups).and_return([tutorial_a])
      end

      it "excludes current group from available targets" do
        targets = component.available_transfer_targets_for(user)
        # Should return only cohorts or empty if no other groups
        expect(targets).to be_empty
      end
    end
  end
end
