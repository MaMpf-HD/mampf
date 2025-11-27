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
  end
end
