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

      def helpers
      end
    end
  end

  let(:group_full) { instance_double("Tutorial", full?: true, id: 1) }
  let(:group_empty) { instance_double("Tutorial", full?: false, id: 2) }
  let(:groups) { [group_full, group_empty] }
  let(:instance) { test_class.new(groups) }

  before do
    allow(instance).to receive(:helpers)
      .and_return(double(group_title_with_capacity: "Group Title"))
  end

  describe "#transfer_targets" do
    let(:group_full) do
      instance_double("Tutorial", full?: true, id: 1, class: Tutorial,
                                  model_name: ActiveModel::Name.new(Tutorial, nil, "Tutorial"))
    end
    let(:group_empty) do
      instance_double("Tutorial", full?: false, id: 2, class: Tutorial,
                                  model_name: ActiveModel::Name.new(Tutorial, nil, "Tutorial"))
    end
    let(:groups) { [group_full, group_empty] }

    before do
      # Mock the human method on the model_name to return the pluralized name
      allow(Tutorial.model_name).to receive(:human).with(count: 2).and_return("Tutorials")
      # Mock I18n translation for the group title
      allow(I18n).to receive(:t).and_call_original
      allow(I18n).to receive(:t).with("registration.item.groups.tutorials").and_return("Tutorials")
    end

    it "returns a list of hashes grouped by type" do
      targets = instance.transfer_targets

      expect(targets.size).to eq(1) # One type: :tutorials
      type_group = targets.first
      expect(type_group[:type]).to eq(:tutorials)
      expect(type_group[:title]).to eq("Tutorials")

      items = type_group[:items]
      expect(items.size).to eq(2)
      expect(items[0]).to include(group: group_full, overbooked: true, title: "Group Title", id: 1)
      expect(items[1]).to include(group: group_empty, overbooked: false, title: "Group Title",
                                  id: 2)
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
