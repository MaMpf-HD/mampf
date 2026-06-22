require "rails_helper"

RSpec.describe(EligibilityHelper, type: :helper) do
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  describe "#eligibility_failure_message" do
    it "renders advice for institutional email mismatches" do
      user = build_stubbed(:confirmed_user, email: "student@play")
      policy = {
        kind: "institutional_email",
        config: { "allowed_domains" => ["uni-heidelberg.de"] },
        outcome: { pass: false, code: :institutional_email_mismatch }
      }

      html = helper.eligibility_failure_message(policy, user: user)

      expect(html).to include("play")
      expect(html).to include("uni-heidelberg.de")
      expect(html).to include(edit_profile_path)
      expect(html).to include('target="_top"')
    end

    it "renders finalization warnings for institutional email mismatches with the current domain" do
      user = build_stubbed(:confirmed_user, email: "student@play")
      policy = {
        kind: "institutional_email",
        config: { "allowed_domains" => ["uni-heidelberg.de"] },
        outcome: { pass: false, code: :institutional_email_mismatch }
      }

      html = helper.eligibility_failure_message(
        policy,
        user: user,
        context: :finalization_warning
      )

      expect(html).to include("play")
      expect(html).to include("uni-heidelberg.de")
      expect(html).to include(edit_profile_path)
      expect(html).to include("will be rejected")
    end

    it "renders finalization rejections for institutional email mismatches " \
       "without the current domain" do
      user = build_stubbed(:confirmed_user, email: "student@play")
      policy = {
        kind: "institutional_email",
        config: { "allowed_domains" => ["uni-heidelberg.de"] },
        outcome: { pass: false, code: :institutional_email_mismatch }
      }

      html = helper.eligibility_failure_message(
        policy,
        user: user,
        context: :finalization_rejection
      )

      expect(html).to include("At the time this registration process was finalized")
      expect(html).to include("uni-heidelberg.de")
      expect(html).not_to include("play")
      expect(html).not_to include(edit_profile_path)
    end

    it "renders advice for institutional email configuration errors" do
      policy = {
        kind: "institutional_email",
        config: {},
        outcome: { pass: false, code: :configuration_error }
      }

      expect(helper.eligibility_failure_message(policy, user: nil))
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

    it "renders phase-specific wording for prerequisite finalization warnings" do
      policy = {
        kind: "prerequisite_campaign",
        config: { "prerequisite_campaign" => "Linear Algebra: Priority registration" },
        outcome: { pass: false, code: :prerequisite_not_met }
      }

      html = helper.eligibility_failure_message(
        policy,
        context: :finalization_warning
      )

      expect(html).to include("If this remains unchanged when the registration process is finalized")
      expect(html).not_to include("before you can register here")
    end

    it "renders phase-specific wording for prerequisite finalization rejections" do
      policy = {
        kind: "prerequisite_campaign",
        config: { "prerequisite_campaign" => "Linear Algebra: Priority registration" },
        outcome: { pass: false, code: :prerequisite_not_met }
      }

      html = helper.eligibility_failure_message(
        policy,
        context: :finalization_rejection
      )

      expect(html).to include("At the time this registration process was finalized")
      expect(html).not_to include("before you can register here")
    end

    it "renders policy overview status labels" do
      pass_policy = {
        kind: "institutional_email",
        config: { "allowed_domains" => ["uni-heidelberg.de"] },
        outcome: { pass: true }
      }
      unclear_policy = {
        kind: "prerequisite_campaign",
        config: { "prerequisite_campaign" => "Priority registration" },
        outcome: { pass: false, code: :prerequisite_campaign_not_found }
      }

      expect(helper.eligibility_policy_status_label(pass_policy))
        .to eq("Currently fulfilled")
      expect(helper.eligibility_policy_status_label(unclear_policy))
        .to eq("Needs clarification")
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
