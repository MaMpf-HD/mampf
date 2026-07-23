require "rails_helper"

RSpec.describe(Rosters::SelfMaterializationService, type: :model) do
  let(:user) { create(:user) }
  let(:rosterable) { instance_double("Tutorial") }
  let(:service) { described_class.new(rosterable, user) }
  let(:maintenance_service) { instance_double(Rosters::MaintenanceService) }

  before do
    allow(Rosters::MaintenanceService).to receive(:new).and_return(maintenance_service)
  end

  describe "#self_add!" do
    before do
      allow(rosterable).to receive(:locked?).and_return(false)
      allow(rosterable).to receive(:full?).and_return(false)
      allow(rosterable).to receive(:config_allow_self_add?).and_return(true)
    end

    it "delegates to MaintenanceService#add_user! with force: false" do
      expect(maintenance_service).to receive(:add_user!).with(user, rosterable, force: false)
      service.self_add!
    end

    context "when rosterable is locked" do
      before { allow(rosterable).to receive(:locked?).and_return(true) }

      it "raises RosterLockedError" do
        expect { service.self_add! }.to raise_error(described_class::RosterLockedError)
      end
    end

    context "when rosterable is full" do
      before { allow(rosterable).to receive(:full?).and_return(true) }

      it "raises RosterFullError" do
        expect { service.self_add! }.to raise_error(described_class::RosterFullError)
      end
    end

    context "when self-add is not allowed" do
      before { allow(rosterable).to receive(:config_allow_self_add?).and_return(false) }

      it "raises SelfAddNotAllowedError" do
        expect { service.self_add! }.to raise_error(described_class::SelfAddNotAllowedError)
      end
    end
  end

  describe "#self_remove!" do
    before do
      allow(rosterable).to receive(:locked?).and_return(false)
      allow(rosterable).to receive(:config_allow_self_remove?).and_return(true)
    end

    it "delegates to MaintenanceService#remove_user!" do
      expect(maintenance_service).to receive(:remove_user!).with(user, rosterable)
      service.self_remove!
    end

    context "when rosterable is locked" do
      before { allow(rosterable).to receive(:locked?).and_return(true) }

      it "raises RosterLockedError" do
        expect { service.self_remove! }.to raise_error(described_class::RosterLockedError)
      end
    end

    context "when self-remove is not allowed" do
      before { allow(rosterable).to receive(:config_allow_self_remove?).and_return(false) }

      it "raises SelfRemoveNotAllowedError" do
        expect { service.self_remove! }.to raise_error(described_class::SelfRemoveNotAllowedError)
      end
    end
  end
end
