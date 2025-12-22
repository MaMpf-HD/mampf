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

        expect(solver_double).to receive(:run)

        service.allocate!
      end

      it "passes options to the solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .with(campaign, allow_unassigned: false)
          .and_return(solver_double)

        expect(solver_double).to receive(:run)

        described_class.new(campaign, allow_unassigned: false).allocate!
      end

      it "returns the allocation result from the solver" do
        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        expected_result = { 1 => 101 }

        allow(Registration::Solvers::MinCostFlow).to receive(:new)
          .and_return(solver_double)
        allow(solver_double).to receive(:run).and_return(expected_result)

        expect(service.allocate!).to eq(expected_result)
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
