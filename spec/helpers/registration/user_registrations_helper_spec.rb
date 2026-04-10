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
      # let(:test_lecture) { create(:lecture, course: create(:course, title: "Test Course")) }
      # let(:pre_campaign) do
      #   create(:registration_campaign,
      #          { id: 42,
      #            description: "Test description",
      #            campaignable: test_lecture })
      # end
      let(:policy) do
        { kind: "prerequisite_campaign",
          config: { "prerequisite_campaign_id" => 42,
                    "prerequisite_campaign" => "Test Course: Test description" } }
      end
      # before do
      #   allow(Registration::Campaign).to receive(:find_by)
      #     .with(id: 42)
      #     .and_return(pre_campaign)
      # end
      # it "adds campaign info to config" do
      #   result = policy
      #   puts("testing with policy: #{policy}")
      # end
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
