require "rails_helper"

RSpec.describe(Registration::AllocationService) do
  let(:campaign) { create(:registration_campaign, :preference_based) }
  let(:item1) { create(:registration_item, registration_campaign: campaign) }
  let(:item2) { create(:registration_item, registration_campaign: campaign) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }

  let(:service) { described_class.new(campaign) }

  describe "#allocate!" do
    context "with min_cost_flow strategy" do
      it "initializes and runs the MinCostFlow solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .with(campaign)
          .and_return(solver_double)

        expect(solver_double).to receive(:run).and_return({})
        service.allocate!
      end

      it "passes options to the solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .with(campaign, force_assignments: true)
          .and_return(solver_double)

        expect(solver_double).to receive(:run).and_return({})
        described_class.new(campaign, force_assignments: true).allocate!
      end
    end

    context "persistence and side effects" do
      let(:solver_double) { instance_double(Registration::Solvers::MinCostFlow) }

      before do
        allow(Registration::Solvers::MinCostFlow).to receive(:new).and_return(solver_double)

        # Setup: User 1 and User 2 registered for Item 1
        create(:registration_user_registration, user: user1,
                                                registration_item: item1,
                                                registration_campaign: campaign,
                                                preference_rank: 1,
                                                status: :pending)
        create(:registration_user_registration, user: user2,
                                                registration_item: item1,
                                                registration_campaign: campaign,
                                                preference_rank: 1,
                                                status: :pending)
      end

      it "updates assigned registrations to confirmed and unassigned to pending" do
        # Solver assigns User 1 to Item 1, but not User 2
        allow(solver_double).to receive(:run).and_return({ user1.id => item1.id })

        service.allocate!

        expect(user1.user_registrations.first.reload).to be_confirmed
        expect(user2.user_registrations.first.reload).to be_pending
      end

      it "creates new registrations for forced assignments (users without prior registration)" do
        # Solver assigns User 3 (who has no registration) to Item 2
        allow(solver_double).to receive(:run).and_return({ user3.id => item2.id })

        expect do
          service.allocate!
        end.to change(Registration::UserRegistration, :count).by(1)

        reg = Registration::UserRegistration.last
        expect(reg.user).to eq(user3)
        expect(reg.registration_item).to eq(item2)
        expect(reg.preference_rank).to be_nil
        expect(reg).to be_confirmed
      end

      it "updates item confirmed_registrations_count" do
        allow(solver_double).to receive(:run).and_return({ user1.id => item1.id })

        service.allocate!

        expect(item1.reload.confirmed_registrations_count).to eq(1)
        expect(item2.reload.confirmed_registrations_count).to eq(0)
      end

      it "updates campaign status and timestamp" do
        allow(solver_double).to receive(:run).and_return({})

        service.allocate!

        expect(campaign.reload).to be_processing
        expect(campaign.last_allocation_calculated_at).to be_present
      end
    end

    context "cleanup logic" do
      let(:solver_double) { instance_double(Registration::Solvers::MinCostFlow) }

      before do
        allow(Registration::Solvers::MinCostFlow).to receive(:new).and_return(solver_double)
        allow(solver_double).to receive(:run).and_return({})
      end

      it "removes previous forced assignments if the user has other preferences" do
        # User 1 has a preference AND a forced assignment from a previous run
        create(:registration_user_registration, user: user1,
                                                registration_item: item1,
                                                registration_campaign: campaign,
                                                preference_rank: 1)
        create(:registration_user_registration, user: user1,
                                                registration_item: item2,
                                                registration_campaign: campaign,
                                                preference_rank: nil,
                                                status: :confirmed)

        service.allocate!

        # Forced assignment should be gone
        expect(Registration::UserRegistration.where(user: user1, preference_rank: nil)).not_to exist
        # Preference should remain
        expect(Registration::UserRegistration.where(user: user1, preference_rank: 1)).to exist
      end

      it "preserves forced assignments if the user has NO other preferences" do
        # User 3 only has a forced assignment (e.g. manually added by admin)
        create(:registration_user_registration, user: user3,
                                                registration_item: item2,
                                                registration_campaign: campaign,
                                                preference_rank: nil,
                                                status: :confirmed)

        service.allocate!

        expect(Registration::UserRegistration.where(user: user3, preference_rank: nil)).to exist
      end
    end

    context "with unknown strategy" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(campaign, strategy: :unknown).allocate!
        end.to raise_error(ArgumentError, /Unknown strategy/)
      end
    end
  end
end
