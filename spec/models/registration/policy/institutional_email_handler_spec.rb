require "rails_helper"

RSpec.describe(Registration::Policy::InstitutionalEmailHandler, type: :model) do
  let(:policy) do
    build(:registration_policy, :institutional_email,
          config: { "allowed_domains" => "uni.example, test.org" })
  end
  let(:handler) { described_class.new(policy) }
  let(:user) { build(:user, email: "student@uni.example") }

  describe "#evaluate" do
    it "passes if email matches allowed domain" do
      result = handler.evaluate(user)
      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:domain_ok)
    end

    it "passes if email matches a subdomain of an allowed domain" do
      user.email = "student@math.uni.example"
      result = handler.evaluate(user)
      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:domain_ok)
    end

    it "fails if email does not match" do
      user.email = "student@other.example"
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:institutional_email_mismatch)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_AUTO_REJECT)
      expect(result[:reason_type]).to eq(Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY)
      expect(result[:reason_code]).to eq(:institutional_email_mismatch)
      expect(result[:reason_label])
        .to eq(I18n.t("registration.policy.errors.email_domain_not_allowed"))
    end

    it "fails if email matches a partial domain suffix but not a subdomain" do
      user.email = "student@fake-uni.example"
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:institutional_email_mismatch)
    end

    it "fails if config is missing" do
      policy.config = {}
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:configuration_error)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_BLOCKER)
      expect(result[:blocker_kind])
        .to eq(Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION)
    end
  end

  describe "#validate" do
    it "adds error if domains are missing" do
      policy.config = {}
      handler.validate
      expect(policy.errors[:allowed_domains])
        .to include(I18n.t("registration.policy.errors.missing_domains"))
    end

    it "silently normalizes a domain with an @ prefix" do
      policy.config = { "allowed_domains" => "@uni.example" }
      handler.validate
      expect(policy.errors[:allowed_domains]).to be_empty
    end

    it "adds error for a full email address" do
      policy.config = { "allowed_domains" => "user@uni.example" }
      handler.validate
      expect(policy.errors[:allowed_domains].join)
        .to include(I18n.t("registration.policy.errors.invalid_domain_format",
                           domain: "user@uni.example"))
    end

    it "adds error for a URL" do
      policy.config = { "allowed_domains" => "https://uni.example" }
      handler.validate
      expect(policy.errors[:allowed_domains].join)
        .to include(I18n.t("registration.policy.errors.invalid_domain_format",
                           domain: "https://uni.example"))
    end

    it "adds error for a domain with spaces" do
      policy.config = { "allowed_domains" => "uni heidelberg.de" }
      handler.validate
      expect(policy.errors[:allowed_domains]).not_to be_empty
    end

    it "adds error for a bare label without a TLD" do
      policy.config = { "allowed_domains" => "uni-heidelberg" }
      handler.validate
      expect(policy.errors[:allowed_domains]).not_to be_empty
    end

    it "does not add errors for valid domains" do
      policy.config = { "allowed_domains" => "uni-heidelberg.de, kit.edu" }
      handler.validate
      expect(policy.errors[:allowed_domains]).to be_empty
    end
  end

  describe "#summary" do
    it "returns pipe separated domains" do
      expect(handler.summary).to eq("uni.example | test.org")
    end
  end
end
