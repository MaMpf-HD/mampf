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
end
