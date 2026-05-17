require "rails_helper"

RSpec.describe(UserRegistrationsHelper, type: :helper) do
  describe "#get_mode_info" do
    it "returns known mode" do
      expect(helper.get_mode_info(0)).to include(:mode_name, :abbr, :badge_class)
    end

    it "returns unknown mode for missing key" do
      expect(helper.get_mode_info(999)).to eq(UserRegistrationsHelper::MODE_MAP[-1])
    end
  end

  describe "#single_mode?" do
    it { expect(helper.single_mode?("Lecture")).to eq(true) }
    it { expect(helper.single_mode?("Tutorial")).to eq(false) }
  end

  describe "#student_registration_campaign_title" do
    it "returns the campaign description when present" do
      campaign = build(:registration_campaign, description: "Localized description")

      expect(helper.student_registration_campaign_title(campaign))
        .to eq("Localized description")
    end

    it "falls back to the default title when the description is blank" do
      campaign = build(:registration_campaign, description: "  ")

      expect(helper.student_registration_campaign_title(campaign))
        .to eq(I18n.t("registration.user_registration.campaign_main"))
    end
  end

  describe "#freely_registerable?" do
    subject(:result) { helper.freely_registerable?(group_type) }

    context "when group_type is 'Cohort'" do
      let(:group_type) { "Cohort" }

      it "returns true" do
        expect(result).to be(true)
      end
    end

    context "when group_type is not 'Cohort'" do
      let(:group_type) { "Tutorial" }

      it "returns false" do
        expect(result).to be(false)
      end
    end

    context "when group_type is nil" do
      let(:group_type) { nil }

      it "returns false" do
        expect(result).to be(false)
      end
    end
  end

  describe("TABLE_CONFIG") do
    subject(:config) { UserRegistrationsHelper::TABLE_CONFIG }
    let(:lecture) { create(:lecture) }
    let(:seminar) { create(:seminar) }
    let(:tutorial) { create(:tutorial, lecture: lecture, location: "Room 101") }
    let(:item_tutorial) { create(:registration_item, registerable: tutorial) }
    let(:talk) do
      create(:talk, lecture: seminar, position: 5, description: "Deep Learning Overview",
                    dates: [
                      Time.zone.local(2026, 4, 10),
                      Time.zone.local(2026, 4, 11)
                    ])
    end
    let(:item_talk) { create(:registration_item, registerable: talk) }
    let(:cohort) do
      create(:cohort, context: lecture, propagate_to_lecture: true, description: "Group A")
    end
    let(:item_cohort) { create(:registration_item, registerable: cohort) }

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
        expect(row2[:field].call(item_tutorial)).to eq("Room 101")
      end
    end

    describe "Talk config" do
      it "defines three rows" do
        expect(config["Talk"].size).to eq(3)
      end

      it "evaluates fields correctly" do
        pos_row, desc_row, date_row = config["Talk"]
        expect(pos_row[:header]).to eq("basics.position")
        expect(pos_row[:field].call(item_talk)).to eq(5)

        expect(desc_row[:header]).to eq("basics.description")
        expect(desc_row[:field].call(item_talk)).to eq("Deep Learning Overview")

        formatted = "Apr 10 2026, Apr 11 2026"
        expect(date_row[:field].call(item_talk)).to eq(formatted)
      end
    end

    describe "Cohort config" do
      it "defines one row" do
        expect(config["Cohort"].size).to eq(1)
      end

      it "evaluates description field" do
        row = config["Cohort"].first

        expect(row[:header]).to eq("basics.description")
        expect(row[:field].call(item_cohort)).to eq("Group A")
      end
    end
  end

  describe "#nullable_capacity_display" do
    it { expect(helper.nullable_capacity_display(nil)).to eq("∞") }
    it { expect(helper.nullable_capacity_display(10)).to eq("10") }
  end

  describe "#format_date" do
    let(:timestamp) { Time.zone.local(2026, 5, 2, 17, 45) }

    it "uses the English student registration format" do
      I18n.with_locale(:en) do
        expect(helper.format_date(timestamp)).to eq("May 2, 17h45")
      end
    end

    it "uses the German student registration format" do
      I18n.with_locale(:de) do
        expect(helper.format_date(timestamp)).to eq("2. Mai, 17h45")
      end
    end
  end
end
