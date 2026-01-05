require "rails_helper"

RSpec.describe(Registration::AllocationDashboard, type: :model) do
  let(:lecture) { create(:lecture) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:dashboard) { described_class.new(campaign) }

  describe "#stats" do
    it "returns allocation stats" do
      expect(dashboard.stats).to be_a(Registration::AllocationStats)
    end
  end

  describe "#unassigned_students" do
    let(:student) { create(:confirmed_user) }

    before do
      create(:registration_user_registration, registration_campaign: campaign, user: student)
    end

    it "returns unassigned students" do
      expect(dashboard.unassigned_students).to include(student)
    end
  end

  describe "#policy_violations" do
    it "returns policy violations" do
      # Assuming default campaign has no violations
      expect(dashboard.policy_violations).to be_empty
    end

    context "when guard fails with status error" do
      before do
        allow_any_instance_of(Registration::FinalizationGuard).to receive(:check).and_return(
          Registration::FinalizationGuard::Result.new(success?: false, error_code: :wrong_status, data: nil)
        )
      end

      it "returns empty array" do
        expect(dashboard.policy_violations).to eq([])
      end
    end
  end

  describe "#conflicting_registrations" do
    context "when there are conflicts" do
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:student) { create(:confirmed_user) }

      before do
        create(:registration_user_registration, registration_campaign: campaign, user: student)
        create(:tutorial_membership, tutorial: tutorial, user: student)
      end

      it "returns conflicting registrations" do
        conflicts = dashboard.conflicting_registrations
        expect(conflicts).to be_present
        expect(conflicts.first[:user]).to eq(student)
        expect(conflicts.first[:tutorial]).to eq(tutorial)
      end
    end

    context "when there are no conflicts" do
      it "returns empty array" do
        expect(dashboard.conflicting_registrations).to be_empty
      end
    end
  end
end
