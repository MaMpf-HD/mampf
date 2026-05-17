require "rails_helper"

RSpec.describe(EligibilityHelper, type: :helper) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  describe "#eligible_for_registration?" do
    it "returns true when all policies pass" do
      eligibility = [
        { kind: "institutional_email", outcome: { pass: true } },
        { kind: "prerequisite_campaign", outcome: { pass: true } }
      ]

      expect(helper.eligible_for_registration?(eligibility)).to be(true)
    end

    it "returns false when one policy fails" do
      eligibility = [
        { kind: "institutional_email", outcome: { pass: true } },
        { kind: "prerequisite_campaign", outcome: { pass: false } }
      ]

      expect(helper.eligible_for_registration?(eligibility)).to be(false)
    end
  end

  describe "#student_registration_ineligible?" do
    let(:eligibility) do
      [{ kind: "institutional_email", outcome: { pass: false } }]
    end

    it "returns true for an incomplete campaign with failed eligibility" do
      campaign = build(:registration_campaign, status: :open)

      expect(helper.student_registration_ineligible?(campaign, eligibility))
        .to be(true)
    end

    it "returns false for completed campaigns" do
      campaign = build(:registration_campaign, :completed)

      expect(helper.student_registration_ineligible?(campaign, eligibility))
        .to be(false)
    end
  end

  describe "#failed_eligibility_policies" do
    it "returns only the failing policies" do
      eligibility = [
        { kind: "institutional_email", outcome: { pass: true } },
        { kind: "prerequisite_campaign", outcome: { pass: false } }
      ]

      expect(helper.failed_eligibility_policies(eligibility))
        .to eq([eligibility.last])
    end
  end

  describe "#eligibility_failure_message" do
    it "renders advice for institutional email mismatches" do
      policy = {
        kind: "institutional_email",
        config: { "allowed_domains" => ["uni-heidelberg.de"] },
        outcome: { pass: false, code: :institutional_email_mismatch }
      }

      html = helper.eligibility_failure_message(policy)

      expect(html).to include("uni-heidelberg.de")
      expect(html).to include(edit_profile_path)
      expect(html).to include('target="_top"')
    end

    it "renders advice for institutional email configuration errors" do
      policy = {
        kind: "institutional_email",
        config: {},
        outcome: { pass: false, code: :configuration_error }
      }

      expect(helper.eligibility_failure_message(policy))
        .to include("not configured")
    end

    it "renders the prerequisite campaign title when that check failed" do
      policy = {
        kind: "prerequisite_campaign",
        config: { "prerequisite_campaign" => "Linear Algebra: Priority registration" },
        outcome: { pass: false, code: :prerequisite_not_met }
      }

      html = helper.eligibility_failure_message(policy)

      expect(html).to include("Linear Algebra: Priority registration")
    end

    it "renders advice for missing prerequisite campaigns" do
      policy = {
        kind: "prerequisite_campaign",
        config: { "prerequisite_campaign" => "Missing campaign" },
        outcome: { pass: false, code: :prerequisite_campaign_not_found }
      }

      expect(helper.eligibility_failure_message(policy))
        .to include("currently unavailable")
    end

    it "renders advice for prerequisite configuration errors" do
      policy = {
        kind: "prerequisite_campaign",
        config: {},
        outcome: { pass: false, code: :configuration_error }
      }

      expect(helper.eligibility_failure_message(policy))
        .to include("not configured correctly")
    end

    it "renders advice for student performance failures" do
      policy = {
        kind: "student_performance",
        config: { "certification_status" => "pending" },
        outcome: { pass: false, code: :student_performance_not_met }
      }

      expect(helper.eligibility_failure_message(policy)).to include("Pending")
    end

    it "falls back to a generic requirement message for unknown policies" do
      policy = {
        kind: "other_requirement",
        config: {},
        outcome: { pass: false, code: :unknown }
      }

      html = helper.eligibility_failure_message(policy)

      expect(html).to include("other requirement")
    end
  end
end
