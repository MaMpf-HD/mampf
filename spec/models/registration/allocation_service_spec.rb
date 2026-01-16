require "rails_helper"

RSpec.describe(Registration::AllocationService) do
  let(:lecture) { create(:lecture) }
  let(:campaign) { create(:registration_campaign, :preference_based, campaignable: lecture) }
  let(:service) { described_class.new(campaign) }

  describe "#allocate!" do
    context "with locking" do
      let(:tutorial1) { create(:tutorial, lecture: lecture, capacity: 10) }
      let(:tutorial2) { create(:tutorial, lecture: lecture, capacity: 10) }

      before do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial1)
        create(:registration_item, registration_campaign: campaign, registerable: tutorial2)
        campaign.update!(status: :closed)
      end

      it "locks campaign and registerables during allocation" do
        locked_objects = []

        allow(campaign).to receive(:lock!) do
          locked_objects << :campaign
          campaign
        end

        allow_any_instance_of(Tutorial).to receive(:lock!) do |tutorial|
          locked_objects << tutorial
          tutorial
        end

        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new).and_return(solver_double)
        allow(solver_double).to receive(:run) do
          expect(locked_objects).to include(:campaign, tutorial1, tutorial2)
          {}
        end

        service.allocate!
      end

      it "prevents concurrent capacity edits during solver execution" do
        locked_registerables = []

        allow_any_instance_of(Tutorial).to receive(:lock!) do |tutorial|
          locked_registerables << tutorial
          tutorial
        end

        solver_double = instance_double(Registration::Solvers::MinCostFlow)
        allow(Registration::Solvers::MinCostFlow).to receive(:new).and_return(solver_double)
        allow(solver_double).to receive(:run) do
          # During solver run, registerables should already be locked
          expect(locked_registerables).to include(tutorial1, tutorial2)
          {}
        end

        service.allocate!
      end
    end

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

    context "with unknown strategy" do
      it "raises an ArgumentError" do
        expect do
          described_class.new(campaign, strategy: :unknown).allocate!
        end.to raise_error(ArgumentError, /Unknown strategy/)
      end
    end
  end
end
