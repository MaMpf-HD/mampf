require "rails_helper"

RSpec.describe(RegistrationPolicyHelper, type: :helper) do
  describe "#available_policy_kinds" do
    let(:campaign) { create(:registration_campaign) }

    context "when creating a new policy" do
      let(:policy) { campaign.registration_policies.build }

      it "includes institutional_email when none exists yet" do
        expect(helper.available_policy_kinds(campaign, policy))
          .to include("institutional_email")
      end

      it "excludes institutional_email when one already exists" do
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign)
        expect(helper.available_policy_kinds(campaign, policy))
          .not_to include("institutional_email")
      end

      it "excludes student_performance" do
        expect(helper.available_policy_kinds(campaign, policy))
          .not_to include("student_performance")
      end
    end

    context "when editing an existing policy" do
      let!(:existing) do
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign)
      end

      it "still includes institutional_email so the current value remains selectable" do
        expect(helper.available_policy_kinds(campaign, existing))
          .to include("institutional_email")
      end
    end
  end
end
