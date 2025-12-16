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

    it "fails if email does not match" do
      user.email = "student@other.example"
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:institutional_email_mismatch)
    end

    it "fails if config is missing" do
      policy.config = {}
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:configuration_error)
    end
  end

  describe "#validate" do
    it "adds error if domains are missing" do
      policy.config = {}
      handler.validate
      expect(policy.errors[:allowed_domains])
        .to include(I18n.t("registration.policy.errors.missing_domains"))
    end
  end

  describe "#summary" do
    it "returns comma separated domains" do
      expect(handler.summary).to eq("uni.example, test.org")
    end
  end
end
