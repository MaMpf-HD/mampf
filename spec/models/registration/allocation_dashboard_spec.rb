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

  describe "#blocker_violations" do
    it "returns no blockers by default" do
      expect(dashboard.blocker_violations).to be_empty
    end

    context "when guard fails with status error" do
      before do
        allow_any_instance_of(Registration::FinalizationGuard).to receive(:check).and_return(
          Registration::FinalizationGuard::Result.new(success?: false, error_code: :wrong_status,
                                                      data: nil)
        )
      end

      it "returns empty array" do
        expect(dashboard.blocker_violations).to eq([])
      end
    end

    context "when guard returns blockers and auto rejects" do
      before do
        allow_any_instance_of(Registration::FinalizationGuard).to receive(:check).and_return(
          Registration::FinalizationGuard::Result.new(
            success?: false,
            error_code: :policy_violation,
            data: [
              { user_id: 1, policy: "A", classification: :blocker },
              { user_id: 2, policy: "B", classification: :auto_reject }
            ]
          )
        )
      end

      it "filters to blockers only" do
        expect(dashboard.blocker_violations).to eq([
                                                     { user_id: 1,
                                                       policy: "A",
                                                       classification: :blocker }
                                                   ])
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

    context "when campaign is already completed" do
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:student) { create(:confirmed_user) }
      let(:completed_campaign) do
        create(:registration_campaign, :completed, campaignable: lecture)
      end
      let(:completed_dashboard) { described_class.new(completed_campaign) }

      before do
        create(:registration_user_registration,
               registration_campaign: completed_campaign, user: student)
        create(:tutorial_membership, tutorial: tutorial, user: student)
      end

      it "returns empty array" do
        expect(completed_dashboard.conflicting_registrations).to be_empty
      end
    end
  end
  describe "#blockers_by_user" do
    it "groups blockers by user_id" do
      allow(dashboard).to receive(:blocker_violations).and_return([
                                                                    { user_id: 1, policy: "A" },
                                                                    { user_id: 1, policy: "B" },
                                                                    { user_id: 2, policy: "A" }
                                                                  ])
      expect(dashboard.blockers_by_user).to eq({
                                                 1 => [{ user_id: 1, policy: "A" },
                                                       { user_id: 1, policy: "B" }],
                                                 2 => [{ user_id: 2, policy: "A" }]
                                               })
    end
  end

  describe "#violations_by_user" do
    it "keeps the compatibility alias pointed at blockers_by_user" do
      grouped = { 1 => [{ user_id: 1, policy: "A" }] }
      allow(dashboard).to receive(:blockers_by_user).and_return(grouped)

      expect(dashboard.violations_by_user).to eq(grouped)
    end
  end

  describe "#blocker_counts_by_policy" do
    it "counts blockers per policy" do
      allow(dashboard).to receive(:blocker_violations).and_return([
                                                                    { user_id: 1, policy: "A" },
                                                                    { user_id: 1, policy: "B" },
                                                                    { user_id: 2, policy: "A" }
                                                                  ])
      expect(dashboard.blocker_counts_by_policy).to eq({ "A" => 2, "B" => 1 })
    end
  end

  describe "#policy_violations" do
    it "keeps the compatibility alias pointed at blocker_violations" do
      blockers = [{ user_id: 1, policy: "A", classification: :blocker }]
      allow(dashboard).to receive(:blocker_violations).and_return(blockers)

      expect(dashboard.policy_violations).to eq(blockers)
    end
  end

  describe "#violation_counts_by_policy" do
    it "keeps the compatibility alias pointed at blocker_counts_by_policy" do
      counts = { "A" => 2 }
      allow(dashboard).to receive(:blocker_counts_by_policy).and_return(counts)

      expect(dashboard.violation_counts_by_policy).to eq(counts)
    end
  end

  describe "#finalization_policies" do
    it "returns active finalization policies for the campaign" do
      policy = create(:registration_policy, registration_campaign: campaign,
                                            active: true, phase: :finalization)
      create(:registration_policy, :student_performance, registration_campaign: campaign,
                                                         active: false, phase: :finalization)
      create(:registration_policy, :student_performance, registration_campaign: campaign,
                                                         active: true, phase: :registration)
      expect(dashboard.finalization_policies).to eq([policy])
    end
  end

  describe "#allocation_run?" do
    it "returns true if last_allocation_calculated_at is present" do
      campaign.update(last_allocation_calculated_at: Time.current)
      expect(dashboard.allocation_run?).to be(true)
    end

    it "returns false if last_allocation_calculated_at is blank" do
      campaign.update(last_allocation_calculated_at: nil)
      expect(dashboard.allocation_run?).to be(false)
    end
  end

  describe "#demand_per_item" do
    let(:campaign) { create(:registration_campaign, :preference_based, campaignable: lecture) }
    let(:item1) { create(:registration_item, registration_campaign: campaign) }
    let(:item2) { create(:registration_item, registration_campaign: campaign) }

    before do
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item1, preference_rank: 1)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item1, preference_rank: 2)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item1, preference_rank: 3)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item1, preference_rank: 4)
      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item1, preference_rank: 5)

      create(:registration_user_registration, registration_campaign: campaign,
                                              registration_item: item2, preference_rank: 1)
    end

    it "calculates demand correctly" do
      demand = dashboard.demand_per_item

      d1 = demand.find { |d| d[:item] == item1 }
      expect(d1[:first]).to eq(1)
      expect(d1[:second]).to eq(1)
      expect(d1[:third]).to eq(1)
      expect(d1[:rest]).to eq(2)
      expect(d1[:total]).to eq(5)

      d2 = demand.find { |d| d[:item] == item2 }
      expect(d2[:first]).to eq(1)
      expect(d2[:second]).to eq(0)
      expect(d2[:total]).to eq(1)
    end
  end

  describe "conflicting_registrations not lecture" do
    let(:course) { create(:course) }
    let(:course_campaign) { create(:registration_campaign, campaignable: course) }
    let(:course_dashboard) { described_class.new(course_campaign) }

    it "returns empty array if campaignable is not a Lecture" do
      expect(course_dashboard.conflicting_registrations).to eq([])
    end
  end
end
