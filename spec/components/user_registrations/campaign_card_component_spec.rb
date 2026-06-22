require "rails_helper"

RSpec.describe(CampaignCardComponent, type: :component) do
  let(:details_class) do
    Struct.new(:eligibility, :finalization_eligibility, :items,
               :item_preferences, keyword_init: true)
  end

  describe "#ineligible?" do
    it "returns false when all policies pass for an open campaign" do
      details = details_class.new(
        eligibility: [
          { kind: "institutional_email", outcome: { pass: true } },
          { kind: "prerequisite_campaign", outcome: { pass: true } }
        ],
        finalization_eligibility: [],
        items: [],
        item_preferences: nil
      )
      component = described_class.new(
        details: details,
        campaign: build(:registration_campaign, status: :open)
      )

      expect(component.ineligible?).to be(false)
    end

    context "with a failing policy" do
      let(:details) do
        details_class.new(
          eligibility: [{ kind: "institutional_email", outcome: { pass: false } }],
          finalization_eligibility: [],
          items: [],
          item_preferences: nil
        )
      end

      it "returns true for an incomplete campaign with failed eligibility" do
        component = described_class.new(
          details: details,
          campaign: build(:registration_campaign, status: :open)
        )

        expect(component.ineligible?).to be(true)
      end

      it "returns false for completed campaigns" do
        component = described_class.new(
          details: details,
          campaign: build(:registration_campaign, :completed)
        )

        expect(component.ineligible?).to be(false)
      end
    end
  end

  describe "#failed_finalization_policies" do
    it "returns only the failing policies when registration is otherwise eligible" do
      passing = { kind: "institutional_email", outcome: { pass: true } }
      failing = { kind: "prerequisite_campaign", outcome: { pass: false } }
      details = details_class.new(
        eligibility: [passing],
        finalization_eligibility: [passing, failing],
        items: [],
        item_preferences: nil
      )
      component = described_class.new(
        details: details,
        campaign: build(:registration_campaign, status: :open)
      )

      expect(component.failed_finalization_policies).to eq([failing])
    end

    it "returns an empty array when the campaign is already ineligible at registration" do
      details = details_class.new(
        eligibility: [{ kind: "institutional_email", outcome: { pass: false } }],
        finalization_eligibility: [{ kind: "prerequisite_campaign", outcome: { pass: false } }],
        items: [],
        item_preferences: nil
      )
      component = described_class.new(
        details: details,
        campaign: build(:registration_campaign, status: :open)
      )

      expect(component.failed_finalization_policies).to eq([])
    end
  end

  describe "#policy_overview_sections" do
    it "includes registration and finalization checks when both are present" do
      details = details_class.new(
        eligibility: [{ kind: "institutional_email", outcome: { pass: true } }],
        finalization_eligibility: [{ kind: "prerequisite_campaign", outcome: { pass: false } }],
        items: [],
        item_preferences: nil
      )
      component = described_class.new(
        details: details,
        campaign: build(:registration_campaign, status: :open)
      )

      expect(component.policy_overview_sections.map { |section| section[:title] })
        .to eq([
                 I18n.t("registration.user_registration.policy_overview.registration_title"),
                 I18n.t("registration.user_registration.policy_overview.finalization_title")
               ])
    end
  end
end
