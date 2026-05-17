require "rails_helper"

RSpec.describe(Rosters::SelfRosterOptionsQuery) do
  describe "#call" do
    let(:user) { create(:confirmed_user) }
    let(:lecture) { create(:lecture) }

    let!(:add_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             skip_campaigns: true,
             self_materialization_mode: :add_only)
    end

    let!(:add_and_remove_tutorial) do
      create(:tutorial,
             lecture: lecture,
             skip_campaigns: true,
             self_materialization_mode: :add_and_remove)
    end

    let!(:remove_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             skip_campaigns: true,
             self_materialization_mode: :remove_only)
    end

    let!(:allocated_remove_only_tutorial) do
      create(:tutorial,
             lecture: lecture,
             skip_campaigns: true,
             self_materialization_mode: :remove_only)
    end

    let!(:disabled_tutorial) do
      create(:tutorial,
             lecture: lecture,
             skip_campaigns: true,
             self_materialization_mode: :disabled)
    end

    before do
      allocated_remove_only_tutorial.add_user_to_roster!(user)
    end

    it "returns joinable rosterables and withdraw-only rosterables the user can leave" do
      result = described_class.new(lecture, user).call

      expect(result.rosterables).to contain_exactly(
        add_only_tutorial,
        add_and_remove_tutorial,
        allocated_remove_only_tutorial
      )
    end
  end
end
