require "rails_helper"

RSpec.describe(Registration::UserRegistrationsHelper, type: :helper) do
  describe "#registration_status_color" do
    let(:registration) { double(status: status) }

    context "when pending" do
      let(:status) { "pending" }
      it { expect(helper.registration_status_color(registration)).to eq("secondary") }
    end

    context "when confirmed" do
      let(:status) { "confirmed" }
      it { expect(helper.registration_status_color(registration)).to eq("success") }
    end

    context "when rejected" do
      let(:status) { "rejected" }
      it { expect(helper.registration_status_color(registration)).to eq("danger") }
    end
  end

  describe "#sort_registrations_by_rank" do
    let(:r1) { double(preference_rank: 2) }
    let(:r2) { double(preference_rank: 1) }
    let(:r3) { double(preference_rank: nil) }

    it "sorts ranked first, then unranked" do
      result = helper.sort_registrations_by_rank([r1, r3, r2])
      expect(result).to eq([r2, r1, r3])
    end
  end

  describe "#get_mode_info" do
    it "returns known mode" do
      expect(helper.get_mode_info(0)).to include(:mode_name, :abbr, :badge_class)
    end

    it "returns unknown mode for missing key" do
      expect(helper.get_mode_info(999)).to eq(Registration::UserRegistrationsHelper::MODE_MAP[-1])
    end
  end

  describe "#get_policy_config_info" do
    context "lecture_performance" do
      let(:policy) do
        { kind: "lecture_performance", config: { "certification_status" => "pending" } }
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
      let(:policy) do
        { kind: "prerequisite_campaign", config: { "prerequisite_campaign_id" => 42 } }
      end
      it { expect(helper.get_policy_config_info(policy)).to eq(42) }
    end

    context "unknown" do
      let(:policy) { { kind: "other", config: {} } }
      it { expect(helper.get_policy_config_info(policy)).to eq("No configuration available") }
    end
  end

  describe "#get_details_render_type_policy_kind" do
    it { expect(helper.get_details_render_type_policy_kind("prerequisite_campaign")).to eq("link") }
    it { expect(helper.get_details_render_type_policy_kind("other")).to eq("text") }
  end

  describe "#single_mode?" do
    it { expect(helper.single_mode?("Lecture")).to eq(true) }
    it { expect(helper.single_mode?("Tutorial")).to eq(false) }
  end

  describe "#format_date" do
    it "formats time" do
      time = Time.zone.local(2024, 1, 1, 14, 30)
      expect(Registration::UserRegistrationsHelper.format_date(time)).to eq("Jan 01, 14:30")
    end

    it "returns empty string for nil" do
      expect(Registration::UserRegistrationsHelper.format_date(nil)).to eq("")
    end
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
      expect(html).to include(I18n.t("registration.eligible"))
      expect(html).to include("text-bg-success")
    end

    it "renders not eligible badge" do
      html = helper.eligibility_badge(false)
      expect(html).to include(I18n.t("registration.not_eligible"))
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

  describe "#status_campaign_style" do
    it { expect(helper.status_campaign_style("open")).to eq("bg-success-subtle text-success") }
    it {
      expect(helper.status_campaign_style("closed")).to eq("bg-secondary-subtle text-secondary")
    }
    it { expect(helper.status_campaign_style("other")).to eq("bg-info-subtle text-info") }
  end
end
