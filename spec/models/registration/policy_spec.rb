require "rails_helper"

RSpec.describe(Registration::Policy, type: :model) do
  describe "factory" do
    it "creates a valid default policy" do
      policy = FactoryBot.create(:registration_policy)
      expect(policy).to be_valid
      expect(policy.kind).to eq("institutional_email")
      expect(policy.phase).to eq("registration")
    end

    it "creates a valid institutional_email policy" do
      policy = FactoryBot.create(:registration_policy, :institutional_email)
      expect(policy).to be_valid
      expect(policy.kind).to eq("institutional_email")
    end

    it "creates a valid lecture_performance policy" do
      policy = FactoryBot.create(:registration_policy, :lecture_performance)
      expect(policy).to be_valid
      expect(policy.kind).to eq("lecture_performance")
    end

    it "creates a valid prerequisite_campaign policy" do
      policy = FactoryBot.create(:registration_policy, :prerequisite_campaign)
      expect(policy).to be_valid
      expect(policy.kind).to eq("prerequisite_campaign")
    end

    describe "#evaluate" do
      let(:user) { FactoryBot.create(:confirmed_user, email: "student@uni.example") }

      it "passes institutional_email when domain is allowed" do
        policy = FactoryBot.build(
          :registration_policy,
          :institutional_email,
          config: { "allowed_domains" => ["uni.example"] }
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(true)
        expect(result[:code]).to eq(:ok)
      end

      it "fails institutional_email when domain is not allowed" do
        policy = FactoryBot.build(
          :registration_policy,
          :institutional_email,
          config: { "allowed_domains" => ["other.example"] }
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(false)
        expect(result[:code]).to eq(:institutional_email_mismatch)
      end

      it "passes prerequisite_campaign when user_registration_confirmed? returns true" do
        campaign = instance_double(Registration::Campaign, user_registration_confirmed?: true)
        allow(Registration::Campaign).to receive(:find_by).and_return(campaign)

        policy = FactoryBot.build(
          :registration_policy,
          :prerequisite_campaign,
          config: { "prerequisite_campaign_id" => 123 }
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(true)
        expect(result[:code]).to eq(:ok)
      end

      it "fails prerequisite_campaign when user_registration_confirmed? returns false" do
        campaign = instance_double(Registration::Campaign, user_registration_confirmed?: false)
        allow(Registration::Campaign).to receive(:find_by).and_return(campaign)

        policy = FactoryBot.build(
          :registration_policy,
          :prerequisite_campaign,
          config: { "prerequisite_campaign_id" => 123 }
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(false)
        expect(result[:code]).to eq(:prerequisite_not_met)
      end

      it "fails prerequisite_campaign when campaign is missing" do
        allow(Registration::Campaign).to receive(:find_by).and_return(nil)

        policy = FactoryBot.build(
          :registration_policy,
          :prerequisite_campaign,
          config: { "prerequisite_campaign_id" => 123 }
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(false)
        expect(result[:code]).to eq(:prerequisite_campaign_not_found)
      end
    end
  end
end
