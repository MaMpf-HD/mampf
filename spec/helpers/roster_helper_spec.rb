require "rails_helper"

RSpec.describe(RosterHelper, type: :helper) do
  describe "#group_title_with_capacity" do
    let(:group) { instance_double("Tutorial", title: "Group A", capacity: 20) }
    let(:roster_entries) { double("RosterEntries", count: 5) }

    before do
      allow(group).to receive(:roster_entries).and_return(roster_entries)
    end

    it "returns title with count and capacity" do
      expect(helper.group_title_with_capacity(group)).to eq("Group A (5/20)")
    end

    context "when capacity is nil" do
      let(:group) { instance_double("Tutorial", title: "Group B", capacity: nil) }

      it "returns title with count and infinity symbol" do
        expect(helper.group_title_with_capacity(group)).to eq("Group B (5/∞)")
      end
    end
  end
end
