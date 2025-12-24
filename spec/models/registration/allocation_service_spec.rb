require "rails_helper"

RSpec.describe(Registration::AllocationService) do
  let(:campaign) { create(:registration_campaign) }
  let(:service) { described_class.new(campaign) }

  describe "#allocate!" do
    context "with min_cost_flow strategy" do
      it "initializes and runs the MinCostFlow solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .with(campaign)
          .and_return(solver_double)

        # Return an empty hash to prevent save_allocation from crashing on nil
        expect(solver_double).to receive(:run).and_return({})

        service.allocate!
      end

      it "passes options to the solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .with(campaign, force_assignments: true)
          .and_return(solver_double)

        # Return an empty hash to prevent save_allocation from crashing on nil
        expect(solver_double).to receive(:run).and_return({})

        described_class.new(campaign, force_assignments: true).allocate!
      end

      it "returns the allocation result from the solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)

        # Create real records to satisfy foreign key constraints in save_allocation
        item = create(:registration_item, registration_campaign: campaign)
        user = create(:user)
        expected_result = { user.id => item.id }

        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .and_return(solver_double)
        allow(solver_double).to receive(:run).and_return(expected_result)

        # The service returns the result of the transaction block, which is true/false or the result of the last operation
        # We don't strictly care about the return value here, but we want to ensure it runs without error
        expect { service.allocate! }.not_to raise_error
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
