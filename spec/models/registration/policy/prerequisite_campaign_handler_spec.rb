require "rails_helper"

RSpec.describe(Registration::Policy::PrerequisiteCampaignHandler, type: :model) do
  let(:prereq) { create(:registration_campaign, :completed) }
  let(:policy) do
    build(:registration_policy, :prerequisite_campaign,
          config: { "prerequisite_campaign_id" => prereq.id })
  end
  let(:handler) { described_class.new(policy) }
  let(:user) { create(:user) }

  describe "#evaluate" do
    it "passes if user is confirmed in prerequisite campaign" do
      create(:registration_user_registration, registration_campaign: prereq, user: user,
                                              status: :confirmed)
      result = handler.evaluate(user)
      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:prerequisite_met)
    end

    it "fails if user is not confirmed" do
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:prerequisite_not_met)
    end

    it "fails if prerequisite campaign is missing" do
      policy.config["prerequisite_campaign_id"] = 99_999
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:prerequisite_campaign_not_found)
    end
  end

  describe "#validate" do
    it "adds error if campaign id is missing" do
      policy.config = {}
      handler.validate
      expect(policy.errors[:prerequisite_campaign_id])
        .to include(I18n.t("registration.policy.errors.missing_prerequisite_campaign"))
    end

    it "adds error if campaign does not exist" do
      policy.config["prerequisite_campaign_id"] = 99_999
      handler.validate
      expect(policy.errors[:prerequisite_campaign_id])
        .to include(I18n.t("registration.policy.errors.prerequisite_campaign_not_found"))
    end
  end

  describe "#summary" do
    it "returns campaign description" do
      expect(handler.summary).to eq(prereq.description)
    end
  end
end
