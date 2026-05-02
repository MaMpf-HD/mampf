require "rails_helper"

RSpec.describe(Registration::UserRegistrationsHelper, type: :helper) do
  describe "#get_mode_info" do
    it "returns known mode" do
      expect(helper.get_mode_info(0)).to include(:mode_name, :abbr, :badge_class)
    end

    it "returns unknown mode for missing key" do
      expect(helper.get_mode_info(999)).to eq(Registration::UserRegistrationsHelper::MODE_MAP[-1])
    end
  end

  describe "#get_policy_config_info" do
    context "student_performance" do
      let(:policy) do
        { kind: "student_performance", config: { "certification_status" => "pending" } }
      end
      it { expect(helper.get_policy_config_info(policy)).to eq("Pending") }
    end

    context "institutional_email" do
      let(:policy) do
        { kind: "institutional_email", config: { "allowed_domains" => ["a.com", "b.com"] } }
      end
      it { expect(helper.get_policy_config_info(policy)).to eq("a.com, b.com") }
    end

    context "prerequisite_campaign" do
      let(:test_lecture) { create(:lecture, course: create(:course, title: "Test Course")) }
      let(:pre_campaign) do
        create(:registration_campaign,
               { id: 42,
                 description: "Test description",
                 campaignable: test_lecture })
      end
      let(:policy) do
        { kind: "prerequisite_campaign",
          config: { "prerequisite_campaign_id" => 42,
                    "prerequisite_campaign" => "Test Course: Test description" } }
      end
      before do
        allow(Registration::Campaign).to receive(:find_by)
          .with(id: 42)
          .and_return(pre_campaign)
      end
      it { expect(helper.get_policy_config_info(policy)).to eq("Test Course: Test description") }
    end

    context "unknown" do
      let(:policy) { { kind: "other", config: {} } }
      it { expect(helper.get_policy_config_info(policy)).to eq("No configuration available") }
    end
  end

  describe "#get_details_render_type_policy_kind" do
    it { expect(helper.get_details_render_type_policy_kind("prerequisite_campaign")).to eq("text") }
    it { expect(helper.get_details_render_type_policy_kind("other")).to eq("text") }
  end

  describe "#single_mode?" do
    it { expect(helper.single_mode?("Lecture")).to eq(true) }
    it { expect(helper.single_mode?("Tutorial")).to eq(false) }
  end

  describe "#get_outcome_info" do
    it "returns the pass outcome" do
      expect(helper.get_outcome_info(pass: true))
        .to eq(Registration::UserRegistrationsHelper::OUTCOME_MAP[true])
    end
    it "returns the fail outcome" do
      expect(helper.get_outcome_info(pass: false))
        .to eq(Registration::UserRegistrationsHelper::OUTCOME_MAP[false])
    end
  end

  describe "#eligibility_badge" do
    it "renders eligible badge" do
      html = helper.eligibility_badge(true)
      expect(html).to include(I18n.t("registration.user_registration.eligible"))
      expect(html).to include("text-bg-success")
    end

    it "renders not eligible badge" do
      html = helper.eligibility_badge(false)
      expect(html).to include(I18n.t("registration.user_registration.not_eligible"))
      expect(html).to include("text-bg-warning")
    end
  end

  describe "#confirm_status_badge" do
    it "renders confirmed badge" do
      html = helper.confirm_status_badge("confirmed")
      expect(html).to include(I18n.t("basics.confirmed"))
      expect(html).to include("text-bg-success")
    end

    it "renders empty span for unknown" do
      expect(helper.confirm_status_badge("weird")).to eq("<span></span>")
    end
  end

  describe "#confirm_status_badge" do
    subject(:badge) { helper.confirm_status_badge(status) }

    shared_examples "a badge" do |translated_text, css_class|
      it "renders the correct span" do
        expect(badge).to include("<span")
        expect(badge).to include(translated_text)
        expect(badge).to include("class=\"#{css_class}\"")
      end
    end

    context "when status is confirmed" do
      let(:status) { "confirmed" }

      include_examples(
        "a badge",
        I18n.t("basics.confirmed"),
        "text-bg-success"
      )
    end

    context "when status is pending" do
      let(:status) { "pending" }

      include_examples(
        "a badge",
        I18n.t("basics.pending"),
        "text-bg-warning"
      )
    end

    context "when status is rejected" do
      let(:status) { "rejected" }

      include_examples(
        "a badge",
        I18n.t("basics.rejected"),
        "text-bg-danger"
      )
    end

    context "when status is dismissed" do
      let(:status) { "dismissed" }

      include_examples(
        "a badge",
        I18n.t("basics.dismissed"),
        "text-bg-danger"
      )
    end

    context "when status is unknown" do
      let(:status) { "something_else" }

      it "renders an empty span" do
        expect(badge).to eq("<span></span>")
      end
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
    subject(:config) { Registration::UserRegistrationsHelper::TABLE_CONFIG }
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

  describe "#sum_of_nullable" do
    it { expect(helper.sum_of_nullable([1, 2, 3])).to eq(6) }
    it { expect(helper.sum_of_nullable([1, nil, 3])).to eq(nil) }
  end

  describe "#nil_or_positive_integer?" do
    it { expect(helper.nil_or_positive_integer?(nil)).to eq(true) }
    it { expect(helper.nil_or_positive_integer?(5)).to eq(true) }
    it { expect(helper.nil_or_positive_integer?(0)).to eq(false) }
    it { expect(helper.nil_or_positive_integer?("x")).to eq(false) }
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
