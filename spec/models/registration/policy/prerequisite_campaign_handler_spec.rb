require "rails_helper"

RSpec.describe(Registration::Policy::PrerequisiteCampaignHandler, type: :model) do
  let(:prerequisite_campaign) { create(:registration_campaign, :with_items) }
  let(:policy) do
    build(:registration_policy, :prerequisite_campaign,
          config: { "prerequisite_campaign_id" => prerequisite_campaign.id })
  end
  let(:handler) { described_class.new(policy) }
  let(:user) { create(:confirmed_user) }

  describe "#evaluate" do
    it "passes if the user is confirmed in the prerequisite campaign" do
      create(:registration_user_registration, :confirmed,
             registration_campaign: prerequisite_campaign,
             registration_item: prerequisite_campaign.registration_items.first,
             user: user)

      result = handler.evaluate(user)

      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:prerequisite_met)
    end

    it "auto-rejects if the prerequisite is not met" do
      result = handler.evaluate(user)

      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:prerequisite_not_met)
      expect(result[:classification]).to eq(:auto_reject)
      expect(result[:reason_type]).to eq("policy")
      expect(result[:reason_code]).to eq(:prerequisite_not_met)
      expect(result[:snapshot]).to include(
        prerequisite_campaign_id: prerequisite_campaign.id,
        prerequisite_campaign_description: prerequisite_campaign.description
      )
    end

    it "returns a blocker if the prerequisite campaign is not configured" do
      policy.config = {}

      result = handler.evaluate(user)

      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:configuration_error)
      expect(result[:classification]).to eq(:blocker)
    end

    it "returns a blocker if the prerequisite campaign cannot be found" do
      policy.config = { "prerequisite_campaign_id" => SecureRandom.uuid }

      result = handler.evaluate(user)

      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:prerequisite_campaign_not_found)
      expect(result[:classification]).to eq(:blocker)
    end
  end
end
