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
              "prerequisite_campaign_id" => prerequisite_campaign.id
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
    end
  end
end
