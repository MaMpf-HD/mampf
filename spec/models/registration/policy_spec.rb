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

    it "creates a valid student_performance policy" do
      policy = FactoryBot.create(:registration_policy, :student_performance)
      expect(policy).to be_valid
      expect(policy.kind).to eq("student_performance")
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
        expect(result[:code]).to eq(:domain_ok)
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
        expect(result[:code]).to eq(:prerequisite_met)
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

      it "fails institutional_email when config is missing" do
        policy = FactoryBot.build(
          :registration_policy,
          :institutional_email,
          config: {}
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(false)
        expect(result[:code]).to eq(:configuration_error)
      end

      it "fails prerequisite_campaign when config is missing" do
        policy = FactoryBot.build(
          :registration_policy,
          :prerequisite_campaign,
          config: {}
        )

        result = policy.evaluate(user)

        expect(result[:pass]).to be(false)
        expect(result[:code]).to eq(:configuration_error)
      end

      it "raises error for unknown policy kind" do
        policy = FactoryBot.build(:registration_policy)
        allow(policy).to receive(:kind).and_return("unknown_kind")

        expect { policy.evaluate(user) }.to raise_error(ArgumentError, /Unknown policy kind/)
      end
    end

    describe "scopes" do
      describe ".for_phase" do
        let(:campaign) { create(:registration_campaign) }
        let!(:registration_policy) do
          create(:registration_policy, registration_campaign: campaign,
                                       phase: :registration)
        end
        let!(:finalization_policy) do
          create(:registration_policy, registration_campaign: campaign,
                                       phase: :finalization)
        end
        let!(:both_policy) do
          create(:registration_policy, registration_campaign: campaign,
                                       phase: :both)
        end

        it "includes policies for the requested phase and 'both'" do
          policies = described_class.for_phase(:registration)
          expect(policies).to include(registration_policy, both_policy)
          expect(policies).not_to include(finalization_policy)
        end

        it "includes policies for finalization phase and 'both'" do
          policies = described_class.for_phase(:finalization)
          expect(policies).to include(finalization_policy, both_policy)
          expect(policies).not_to include(registration_policy)
        end
      end
    end
  end
end
