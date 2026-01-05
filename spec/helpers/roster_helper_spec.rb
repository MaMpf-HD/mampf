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

  describe "#roster_group_types" do
    let(:lecture) { instance_double("Lecture", seminar?: is_seminar) }

    context "when lecture is a seminar" do
      let(:is_seminar) { true }

      it "returns [:talks, :cohorts]" do
        expect(helper.roster_group_types(lecture)).to eq([:talks, :cohorts])
      end
    end

    context "when lecture is not a seminar" do
      let(:is_seminar) { false }

      it "returns [:tutorials, :cohorts]" do
        expect(helper.roster_group_types(lecture)).to eq([:tutorials, :cohorts])
      end
    end
  end

  describe "#roster_maintenance_frame_id" do
    it "handles single symbol" do
      expect(helper.roster_maintenance_frame_id(:tutorials)).to eq("roster_maintenance_tutorials")
    end

    it "handles array of symbols" do
      expect(helper.roster_maintenance_frame_id([:tutorials,
                                                 :cohorts]))
        .to eq("roster_maintenance_tutorials_cohorts")
    end
  end

  describe "#hidden_group_type_field" do
    it "renders single hidden field for symbol" do
      expected = '<input type="hidden" name="group_type" id="group_type" ' \
                 'value="tutorials" autocomplete="off" />'
      expect(helper.hidden_group_type_field(:tutorials)).to eq(expected)
    end

    it "renders multiple hidden fields for array" do
      expected = '<input type="hidden" name="group_type[]" id="group_type_" ' \
                 'value="tutorials" autocomplete="off" />' \
                 '<input type="hidden" name="group_type[]" id="group_type_" ' \
                 'value="cohorts" autocomplete="off" />'
      expect(helper.hidden_group_type_field([:tutorials, :cohorts])).to eq(expected)
    end
  end

  describe "#roster_manage_button" do
    let(:lecture) { create(:lecture) }
    let(:component) { double("RosterOverviewComponent", lecture: lecture) }
    let(:item) { create(:tutorial, lecture: lecture) }
    let(:campaign) { nil }

    before do
      allow(component).to receive(:group_path).with(item).and_return("/tutorials/#{item.id}/roster")
    end

    context "when item is not locked" do
      before { allow(item).to receive(:locked?).and_return(false) }

      it "renders manage participants button" do
        result = helper.roster_manage_button(item, component, campaign)
        expect(result).to include("href=\"/tutorials/#{item.id}/roster\"")
        expect(result).to include("bi-person-lines-fill")
      end
    end

    context "when item is locked" do
      before { allow(item).to receive(:locked?).and_return(true) }

      context "with campaign" do
        let(:campaign) { create(:registration_campaign) }

        it "renders view campaign button" do
          result = helper.roster_manage_button(item, component, campaign)
          expect(result).to include("campaign_id=#{campaign.id}")
          expect(result).to include("bi-calendar-check")
        end
      end

      context "without campaign and not in real campaign" do
        before { allow(item).to receive(:in_real_campaign?).and_return(false) }

        it "renders create campaign button" do
          result = helper.roster_manage_button(item, component, campaign)
          expect(result).to include("new_campaign=true")
          expect(result).to include("bi-calendar-plus")
        end
      end
    end
  end

  describe "#roster_edit_button" do
    let(:item) { create(:tutorial) }

    it "renders edit button" do
      result = helper.roster_edit_button(item, :tutorials)
      expect(result).to include("href=\"/tutorials/#{item.id}/edit?group_type=tutorials\"")
      expect(result).to include("bi-tools")
    end
  end

  describe "#roster_destroy_button" do
    let(:item) { create(:tutorial) }

    context "when item is destructible" do
      before { allow(item).to receive(:destructible?).and_return(true) }

      it "renders delete button" do
        result = helper.roster_destroy_button(item, :tutorials)
        expect(result).to include("href=\"/tutorials/#{item.id}?group_type=tutorials\"")
        expect(result).to include("data-turbo-method=\"delete\"")
        expect(result).to include("bi-trash")
      end
    end

    context "when item is not destructible" do
      before { allow(item).to receive(:destructible?).and_return(false) }

      it "returns nil" do
        expect(helper.roster_destroy_button(item, :tutorials)).to be_nil
      end
    end
  end
end
