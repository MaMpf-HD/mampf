require "rails_helper"

RSpec.describe(UserRegistrations::CampaignDetailsService, type: :service) do
  let(:user)     { create(:confirmed_user) }
  let(:teacher)  { create(:confirmed_user) }
  let(:lecture)  { create(:lecture, teacher: teacher) }

  let(:campaign) do
    create(:registration_campaign, :open, :preference_based, campaignable: lecture)
  end

  let!(:item1) { create(:registration_item, registration_campaign: campaign) }
  let!(:item2) { create(:registration_item, registration_campaign: campaign) }

  subject(:service) { described_class.new(campaign, user) }

  describe "#call" do
    it "returns a Result struct with expected fields" do
      allow(service).to receive(:eligibility).and_return(["ok"])
      allow(service).to receive(:items).and_return([item1, item2])
      allow(service).to receive(:item_preferences).and_return(:prefs)

      result = service.call

      expect(result.campaign).to eq(campaign)
      expect(result.eligibility).to eq(["ok"])
      expect(result.items).to eq([item1, item2])
      expect(result.item_preferences).to eq(:prefs)
    end
  end

  describe "#eligibility" do
    let(:policy_engine) { instance_double(Registration::PolicyEngine) }

    before do
      allow(Registration::PolicyEngine).to receive(:new)
        .with(campaign)
        .and_return(policy_engine)
    end

    context "when prerequisite campaign exists" do
      let(:prereq_campaign) do
        create(:registration_campaign, :open, campaignable: lecture, description: "Prereq Desc")
      end

      let(:trace) do
        [
          {
            kind: "prerequisite_campaign",
            config: { "prerequisite_campaign_id" => prereq_campaign.id }
          }
        ]
      end

      it "replaces prerequisite_campaign_id with formatted string" do
        allow(policy_engine).to receive(:full_trace_with_config_for)
          .with(user, phase: :registration)
          .and_return(trace)

        result = service.eligibility

        expect(result.first[:config]["prerequisite_campaign"])
          .to eq("Prereq Desc")
      end
    end

    context "when prerequisite campaign does not exist" do
      let(:trace) do
        [
          {
            kind: "prerequisite_campaign",
            config: { "prerequisite_campaign_id" => 999_999 }
          }
        ]
      end

      it "sets prerequisite_campaign to 'Campaign not found'" do
        allow(policy_engine).to receive(:full_trace_with_config_for)
          .with(user, phase: :registration)
          .and_return(trace)

        result = service.eligibility

        expect(result.first[:config]["prerequisite_campaign"])
          .to eq(I18n.t("registration.campaign.not_found"))
      end
    end
  end
end
