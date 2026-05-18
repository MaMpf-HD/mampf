require "rails_helper"

RSpec.describe(Registration::PolicyEngine, type: :service) do
  describe "#eligible?" do
    let(:campaign) { FactoryBot.create(:registration_campaign) }
    let(:user) { FactoryBot.create(:user, email: "student@uni.example") }

    it "returns pass: true when all policies pass" do
      policy1 = FactoryBot.create(
        :registration_policy,
        :institutional_email,
        registration_campaign: campaign,
        position: 1,
        config: { "allowed_domains" => ["uni.example"] }
      )

      prereq_campaign = FactoryBot.create(:registration_campaign)
      FactoryBot.create(
        :registration_user_registration,
        registration_campaign: prereq_campaign,
        user: user,
        status: :confirmed
      )

      policy2 = FactoryBot.create(
        :registration_policy,
        :prerequisite_campaign,
        registration_campaign: campaign,
        position: 2,
        config: { "prerequisite_campaign_id" => prereq_campaign.id }
      )

      engine = described_class.new(campaign)
      result = engine.eligible?(user, phase: :registration)

      expect(result.pass).to be(true)
      expect(result.failed_policy).to be_nil
      expect(result.trace.size).to eq(2)
      expect(result.trace.pluck(:policy_id)).to match_array([policy1.id, policy2.id])
      expect(result.trace.first.keys).to include(:policy_id, :kind, :phase, :outcome)
    end

    it "short-circuits on first failing policy" do
      FactoryBot.create(
        :registration_policy,
        :institutional_email,
        registration_campaign: campaign,
        position: 1,
        config: { "allowed_domains" => ["other.example"] }
      )

      prereq_campaign = FactoryBot.create(:registration_campaign)
      FactoryBot.create(
        :registration_user_registration,
        registration_campaign: prereq_campaign,
        user: user,
        status: :confirmed
      )

      FactoryBot.create(
        :registration_policy,
        :prerequisite_campaign,
        registration_campaign: campaign,
        position: 2,
        config: { "prerequisite_campaign_id" => prereq_campaign.id }
      )

      engine = described_class.new(campaign)
      result = engine.eligible?(user, phase: :registration)

      expect(result.pass).to be(false)
      expect(result.failed_policy).to eq(campaign.registration_policies.order(:position).first)
      expect(result.trace.size).to eq(1)
      expect(result.trace.first[:outcome][:pass]).to be(false)
    end
  end
end
