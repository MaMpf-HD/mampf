require "rails_helper"

RSpec.describe(RosterHelper, type: :helper) do
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

  describe "#show_muesli_transition_banner?" do
    let(:term) { create(:term, :winter, year: 2026) }
    let(:lecture) { instance_double("Lecture", term: term) }

    after { Flipper.disable(:term_uses_mampf_registration) }

    it "shows the banner while the term is not on MaMpf registration" do
      expect(helper.show_muesli_transition_banner?(lecture)).to be(true)
    end

    it "hides the banner once the term is opted into MaMpf registration" do
      Flipper.enable_actor(:term_uses_mampf_registration, term)

      expect(helper.show_muesli_transition_banner?(lecture)).to be(false)
    end

    it "hides the banner when the lecture has no term (nothing to name)" do
      expect(helper.show_muesli_transition_banner?(instance_double("Lecture", term: nil)))
        .to be(false)
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

    it "disables turbo for full-page navigation" do
      badge = helper.roster_group_badge(tutorial, group_type)
      expect(badge).to include('data-turbo="false"')
    end
  end

  describe "#rosterable_display_type" do
    let(:lecture) { create(:lecture) }
    let(:seminar) { create(:seminar) }
    context "for Tutorial" do
      let(:tutorial) { create(:tutorial, lecture: lecture) }

      it "returns tutorial type label" do
        expect(helper.rosterable_display_type(tutorial))
          .to eq(I18n.t("registration.item.types.tutorial"))
      end
    end

    context "for Talk" do
      let(:talk) { create(:talk, lecture: seminar, position: 5) }

      it "returns talk type label with position" do
        expect(helper.rosterable_display_type(talk))
          .to eq("#{I18n.t("registration.item.types.talk")} 5")
      end
    end

    context "for Cohort" do
      context "with propagation" do
        let(:cohort) { create(:cohort, context: lecture, propagate_to_lecture: true) }

        it "returns group label without icon" do
          expect(helper.rosterable_display_type(cohort))
            .to eq(I18n.t("registration.item.types.other_group"))
        end
      end

      context "without propagation" do
        let(:cohort) { create(:cohort, context: lecture, propagate_to_lecture: false) }

        it "returns group label with no-propagation icon" do
          result = helper.rosterable_display_type(cohort)
          expect(result).to include(I18n.t("registration.item.types.other_group"))
          expect(result).to include("bi-person-x")
          expect(result).to include(I18n.t("registration.item.hints.no_propagation"))
        end
      end
    end

    context "for unknown type" do
      let(:something) { double("UnknownType") }

      it "returns nil safely" do
        expect(helper.rosterable_display_type(something)).to be_nil
      end
    end
  end

  describe("SELF_ROSTER_TABLE_CONFIG") do
    subject(:config) { RosterHelper::SELF_ROSTER_TABLE_CONFIG }
    let(:lecture) { create(:lecture) }
    let(:seminar) { create(:seminar) }
    let(:tutorial) { create(:tutorial, lecture: lecture, location: "Room 101") }
    let(:talk) do
      create(:talk, lecture: seminar, position: 5, description: "Deep Learning Overview",
                    dates: [
                      Time.zone.local(2026, 4, 10),
                      Time.zone.local(2026, 4, 11)
                    ])
    end
    let(:cohort) do
      create(:cohort, context: lecture, propagate_to_lecture: true, description: "Group A")
    end

    describe "Tutorial config" do
      it "defines two rows" do
        expect(config["Tutorial"].size).to eq(2)
      end

      it "has correct headers and fields" do
        row1 = config["Tutorial"][0]
        row2 = config["Tutorial"][1]

        expect(row1[:header]).to eq("basics.tutor")
        expect(row1[:icon]).to eq("person")
        expect(row1[:cell_class]).to eq("text-start fw-semibold")

        expect(row2[:header]).to eq("basics.location")
        expect(row2[:icon]).to eq("location")
        expect(row2[:field].call(tutorial)).to eq("Room 101")
      end
    end

    describe "Talk config" do
      it "defines three rows" do
        expect(config["Talk"].size).to eq(3)
      end

      it "evaluates fields correctly" do
        pos_row, desc_row, date_row = config["Talk"]
        expect(pos_row[:header]).to eq("basics.position")
        expect(pos_row[:field].call(talk)).to eq(5)

        expect(desc_row[:header]).to eq("basics.description")
        expect(desc_row[:field].call(talk)).to eq("Deep Learning Overview")

        formatted = "Apr 10 2026, Apr 11 2026"
        expect(date_row[:field].call(talk)).to eq(formatted)
      end

      it "handles nil dates" do
        talk_with_nil = instance_double("Talk", position: 1, description: "X", dates: [nil])
        _, _, date_row = config["Talk"]

        expect(date_row[:field].call(talk_with_nil)).to eq("")
      end
    end

    describe "Cohort config" do
      it "defines one row" do
        expect(config["Cohort"].size).to eq(1)
      end

      it "evaluates description field" do
        row = config["Cohort"].first

        expect(row[:header]).to eq("basics.description")
        expect(row[:field].call(cohort)).to eq("Group A")
      end
    end
  end

  describe "metadata icons" do
    let(:lecture) { create(:lecture) }
    let(:seminar) { create(:seminar) }
    let(:talk) do
      create(:talk, lecture: seminar, position: 5, description: "Deep Learning Overview",
                    dates: [Time.zone.local(2026, 4, 10)])
    end
    let(:cohort) do
      create(:cohort, context: lecture, propagate_to_lecture: true, description: "Group A")
    end

    it "maps talk metadata icons" do
      expect(helper.rosterable_tile_metadata_rows(talk).pluck(:icon))
        .to eq(["bi-list-ol", "bi-card-text", "bi-calendar-event"])
    end

    it "maps cohort metadata icons" do
      expect(helper.rosterable_tile_metadata_rows(cohort).pluck(:icon))
        .to eq(["bi-card-text"])
    end

    it "falls back to a generic icon for unknown names" do
      expect(helper.send(:gtile_icon_for, "unknown")).to eq("bi-tag")
    end
  end
end
