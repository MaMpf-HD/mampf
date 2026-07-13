require "rails_helper"

RSpec.describe(UserRegistrations::EligibilityTraceService, type: :service) do
  let(:user) { create(:confirmed_user) }
  let(:campaign) { create(:registration_campaign, :open) }
  let(:policy_engine) { instance_double(Registration::PolicyEngine) }

  subject(:service) do
    described_class.new(campaign, user, phase: :registration)
  end

  before do
    allow(Registration::PolicyEngine).to receive(:new)
      .with(campaign)
      .and_return(policy_engine)
  end

  describe "#call" do
    context "when the prerequisite campaign description is blank" do
      let(:prerequisite_campaign) do
        create(:registration_campaign, :open, description: "   ")
      end

      let(:trace) do
        [
          {
            kind: "prerequisite_campaign",
            config: {
              "prerequisite_campaign_id" => prerequisite_campaign.id,
              "metadata" => { "source" => "policy" }
            }
          }
        ]
      end

      it "uses the student-facing campaign title" do
        allow(policy_engine).to receive(:full_trace_with_config_for)
          .with(user, phase: :registration)
          .and_return(trace)

        result = service.call

        expect(result.first[:config]["prerequisite_campaign"])
          .to eq(prerequisite_campaign.student_facing_title)
      end

      it "does not mutate the original policy config" do
        original_config = trace.first[:config]
        expected_original_config = original_config.deep_dup

        allow(policy_engine).to receive(:full_trace_with_config_for)
          .with(user, phase: :registration)
          .and_return(trace)

        result = service.call

        expect(result.first[:config]).not_to equal(original_config)
        expect(result.first[:config]["metadata"])
          .not_to equal(original_config["metadata"])
        expect(original_config).to eq(expected_original_config)
      end
    end

    context "when the trace has no config" do
      let(:policy) do
        Registration::Policy.new(
          registration_campaign: campaign,
          kind: :prerequisite_campaign,
          phase: :registration,
          config: nil
        )
      end

      let(:trace) do
        [
          {
            kind: "prerequisite_campaign",
            config: policy.config
          }
        ]
      end

      it "decorates an empty config hash without mutating the original policy" do
        allow(policy_engine).to receive(:full_trace_with_config_for)
          .with(user, phase: :registration)
          .and_return(trace)

        result = service.call

        expect(result.first[:config])
          .to eq("prerequisite_campaign" => I18n.t("registration.campaign.not_found"))
        expect(policy.config).to be_nil
      end
    end
  end
end
