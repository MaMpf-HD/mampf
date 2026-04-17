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

  describe "#prerequisite_campaign_options" do
    let(:lecture) { create(:lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture) }

    it "excludes the current campaign" do
      other = create(:registration_campaign, campaignable: lecture)
      expect(helper.prerequisite_campaign_options(campaign)).to eq([other])
    end

    it "returns campaigns from the same campaignable" do
      other_lecture = create(:lecture)
      create(:registration_campaign, campaignable: other_lecture)
      other = create(:registration_campaign, campaignable: lecture)
      expect(helper.prerequisite_campaign_options(campaign)).to eq([other])
    end

    it "returns empty array when no other campaigns exist" do
      expect(helper.prerequisite_campaign_options(campaign)).to be_empty
    end
  end

  describe "#prerequisite_campaign_preselect" do
    let(:lecture) { create(:lecture) }
    let(:campaign) { create(:registration_campaign, campaignable: lecture) }
    let(:other) { create(:registration_campaign, campaignable: lecture) }

    context "when policy is persisted" do
      let(:policy) do
        create(:registration_policy, :prerequisite_campaign,
               registration_campaign: campaign).tap do |p|
          p.prerequisite_campaign_id = other.id
          p.save!
        end
      end

      it "returns the saved prerequisite_campaign_id regardless of options count" do
        options = [other]
        expect(helper.prerequisite_campaign_preselect(policy, options))
          .to eq(other.id)
      end

      it "does not auto-pick when options list differs from saved value" do
        third = create(:registration_campaign, campaignable: lecture)
        options = [third]
        expect(helper.prerequisite_campaign_preselect(policy, options))
          .to eq(other.id)
      end
    end

    context "when policy is new" do
      let(:policy) { campaign.registration_policies.build }

      it "auto-picks when exactly one option exists" do
        expect(helper.prerequisite_campaign_preselect(policy, [other]))
          .to eq(other.id)
      end

      it "returns nil when multiple options exist" do
        third = create(:registration_campaign, campaignable: lecture)
        expect(helper.prerequisite_campaign_preselect(policy, [other, third]))
          .to be_nil
      end

      it "returns nil when no options exist" do
        expect(helper.prerequisite_campaign_preselect(policy, []))
          .to be_nil
      end
    end
  end
end
