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

        it "renders disabled manage button" do
          result = helper.roster_manage_button(item, component, campaign)
          expect(result).to include("disabled")
          expect(result).to include("bi-person-lines-fill")
        end
      end

      context "without campaign and not in campaign" do
        before { allow(item).to receive(:in_campaign?).and_return(false) }

        it "renders disabled manage button" do
          result = helper.roster_manage_button(item, component, campaign)
          expect(result).to include("disabled")
          expect(result).to include("bi-person-lines-fill")
        end
      end
    end
  end

  describe "#roster_campaign_button" do
    let(:item) { create(:tutorial) }
    let(:component) do
      double("component", lecture: create(:lecture), group_path: "/tutorials/#{item.id}/roster")
    end

    context "with active campaign" do
      let(:campaign) { create(:registration_campaign) }

      it "renders view campaign button" do
        result = helper.roster_campaign_button(item, component, campaign)
        expect(result).to include("campaign_id=#{campaign.id}")
        expect(result).to include("bi-calendar-event")
      end
    end

    context "without campaign and not in campaign" do
      let(:campaign) { nil }

      before do
        allow(item).to receive(:in_campaign?).and_return(false)
        allow(item).to receive(:skip_campaigns?).and_return(false)
      end

      it "renders create campaign button" do
        result = helper.roster_campaign_button(item, component, campaign)
        expect(result).to include("new_campaign=true")
        expect(result).to include("bi-calendar-plus")
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

      it "renders disabled destroy button" do
        result = helper.roster_destroy_button(item, :tutorials)
        expect(result).to include("disabled")
        expect(result).to include("bi-trash")
      end
    end
  end

  describe "#roster_group_badge" do
    let(:group_type) { :tutorials }
    let(:tutorial) { create(:tutorial, title: "Tut 1") }
    let(:active_cohort) { create(:cohort, title: "Active", propagate_to_lecture: true) }
    let(:isolated_cohort) { create(:cohort, title: "Isolated", propagate_to_lecture: false) }

    it "renders primary badge for tutorial" do
      badge = helper.roster_group_badge(tutorial, group_type)
      expect(badge).to include("bg-secondary")
      expect(badge).to include("Tut 1")
    end

    it "renders primary badge for propagating cohort" do
      badge = helper.roster_group_badge(active_cohort, group_type)
      expect(badge).to include("bg-secondary")
      expect(badge).to include("Active")
    end

    it "renders secondary badge for isolated cohort" do
      badge = helper.roster_group_badge(isolated_cohort, group_type)
      expect(badge).to include("bg-light")
      expect(badge).to include("text-dark")
      expect(badge).to include("Isolated")
    end

    it "sets turbo frame data attribute" do
      badge = helper.roster_group_badge(tutorial, group_type)
      # Check key parts of the turbo frame attribute
      expect(badge).to include('data-turbo-frame="roster_maintenance_tutorials"')
    end
  end

  describe "#should_display_cohort_purpose?" do
    it "returns true when purpose is present and not general" do
      cohort = instance_double("Cohort", purpose: "enrollment")
      expect(helper.should_display_cohort_purpose?(cohort)).to be(true)
    end

    it "returns false when purpose is general" do
      cohort = instance_double("Cohort", purpose: "general")
      expect(helper.should_display_cohort_purpose?(cohort)).to be(false)
    end

    it "returns false when purpose is nil" do
      cohort = instance_double("Cohort", purpose: nil)
      expect(helper.should_display_cohort_purpose?(cohort)).to be(false)
    end

    it "returns false when purpose is blank" do
      cohort = instance_double("Cohort", purpose: "")
      expect(helper.should_display_cohort_purpose?(cohort)).to be(false)
    end
  end

  describe "#item_overbooked?" do
    it "returns true when roster entries exceed capacity" do
      roster_entries = double("RosterEntries", count: 15)
      item = instance_double("Tutorial", roster_entries: roster_entries,
                                         capacity: 10)
      expect(helper.item_overbooked?(item)).to be(true)
    end

    it "returns false when roster entries equal capacity" do
      roster_entries = double("RosterEntries", count: 10)
      item = instance_double("Tutorial", roster_entries: roster_entries,
                                         capacity: 10)
      expect(helper.item_overbooked?(item)).to be(false)
    end

    it "returns false when roster entries are below capacity" do
      roster_entries = double("RosterEntries", count: 5)
      item = instance_double("Tutorial", roster_entries: roster_entries,
                                         capacity: 10)
      expect(helper.item_overbooked?(item)).to be(false)
    end

    it "returns false when capacity is nil" do
      roster_entries = double("RosterEntries", count: 100)
      item = instance_double("Tutorial", roster_entries: roster_entries,
                                         capacity: nil)
      expect(helper.item_overbooked?(item)).to be(false)
    end
  end

  describe "#tutor_names_with_fallback" do
    it "returns tutor names when present" do
      tutorial = instance_double("Tutorial", tutor_names: "Alice, Bob")
      expect(helper.tutor_names_with_fallback(tutorial)).to eq("Alice, Bob")
    end

    it "returns TBA when tutor names are blank" do
      tutorial = instance_double("Tutorial", tutor_names: "")
      expect(helper.tutor_names_with_fallback(tutorial)).to eq("TBA")
    end

    it "returns TBA when tutor names are nil" do
      tutorial = instance_double("Tutorial", tutor_names: nil)
      expect(helper.tutor_names_with_fallback(tutorial)).to eq("TBA")
    end

    it "returns TBA when tutor names are whitespace" do
      tutorial = instance_double("Tutorial", tutor_names: "   ")
      expect(helper.tutor_names_with_fallback(tutorial)).to eq("TBA")
    end
  end
end
