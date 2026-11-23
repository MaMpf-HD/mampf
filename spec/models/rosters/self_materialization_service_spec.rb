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

    it "delegates to MaintenanceService#add_user! with ignore_capacity: false" do
      expect(maintenance_service).to receive(:add_user!)
        .with(user, rosterable, ignore_capacity: false)
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
      allow(rosterable).to receive(:lock!)
      allow(rosterable).to receive(:lecture).and_return(nil)
    end

    it "delegates to MaintenanceService#remove_user!, as removed by the user" do
      expect(maintenance_service).to receive(:remove_user!)
        .with(user, rosterable, by: user, notify: false)
      service.self_remove!
    end

    it "locks the group before the lecture, as the removal does" do
      lecture = create(:lecture)
      order = []
      allow(rosterable).to receive_messages(lecture: lecture, enrolls_in_lecture?: true)
      allow(rosterable).to receive(:lock!) { order << :group }
      allow(lecture).to receive(:lock!) { order << :lecture }
      allow(Rosters::LectureLeave).to receive(:new)
        .and_return(instance_double(Rosters::LectureLeave, only_place?: false))
      allow(maintenance_service).to receive(:remove_user!)

      service.self_remove!

      expect(order).to eq([:group, :lecture])
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

    context "with a student enrolled in the lecture" do
      let(:lecture) { create(:lecture) }
      let(:rosterable) do
        create(:tutorial, lecture: lecture, skip_campaigns: true,
                          self_materialization_mode: :add_and_remove)
      end

      before do
        allow(rosterable).to receive_messages(lock!: rosterable, lecture: lecture)
        lecture.add_user_to_roster!(user)
        rosterable.add_user_to_roster!(user)
      end

      it "lets them leave their only group" do
        expect(maintenance_service).to receive(:remove_user!)
          .with(user, rosterable, by: user, notify: false)
        service.self_remove!
      end

      it "raises LastGroupHeldError while a result or a closed exam registration holds them" do
        allow(Rosters::LectureLeave).to receive(:new).and_return(
          instance_double(Rosters::LectureLeave, only_place?: true, last_place_blockers: [:held])
        )

        expect(maintenance_service).not_to receive(:remove_user!)
        expect { service.self_remove! }.to raise_error(described_class::LastGroupHeldError)
      end

      it "lets them leave a group while another group with enrollment remains" do
        create(:cohort, :enrollment, context: lecture, skip_campaigns: true)
          .add_user_to_roster!(user)

        expect(maintenance_service).to receive(:remove_user!)
          .with(user, rosterable, by: user, notify: false)
        service.self_remove!
      end
    end
  end
end
