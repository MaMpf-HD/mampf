require "rails_helper"

RSpec.describe(RosterTransferable) do
  # Create a dummy class to include the module
  let(:test_class) do
    Class.new do
      include RosterTransferable

      attr_accessor :available_groups

      def initialize(groups)
        @available_groups = groups
      end
    end
  end

  let(:group_full) { instance_double("Tutorial", full?: true) }
  let(:group_empty) { instance_double("Tutorial", full?: false) }
  let(:groups) { [group_full, group_empty] }
  let(:instance) { test_class.new(groups) }

  describe "#transfer_targets" do
    it "returns a list of hashes with group and overbooked status" do
      targets = instance.transfer_targets

      expect(targets.size).to eq(2)
      expect(targets[0]).to include(group: group_full, overbooked: true)
      expect(targets[1]).to include(group: group_empty, overbooked: false)
    end

    it "memoizes the result" do
      expect(instance.transfer_targets.object_id).to eq(instance.transfer_targets.object_id)
    end
  end

  describe "#overbooked?" do
    it "returns true if group is full" do
      expect(instance.overbooked?(group_full)).to be(true)
    end

    it "returns false if group is not full" do
      expect(instance.overbooked?(group_empty)).to be(false)
    end
  end
end
