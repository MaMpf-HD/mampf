require "rails_helper"

RSpec.describe(Assessment::Participation, type: :model) do
  describe "factory" do
    it "creates a valid default participation" do
      participation = FactoryBot.create(:assessment_participation)
      expect(participation).to be_valid
    end

    it "creates a participation with tutorial" do
      participation = FactoryBot.create(:assessment_participation, :with_tutorial)
      expect(participation.tutorial).to be_present
    end

    it "creates a pending participation" do
      participation = FactoryBot.create(:assessment_participation, :pending)
      expect(participation.status).to eq("pending")
      expect(participation.submitted_at).to be_nil
    end

    it "creates a submitted participation" do
      participation = FactoryBot.create(:assessment_participation, :submitted)
      expect(participation.status).to eq("pending")
      expect(participation.submitted_at).to be_present
    end

    it "creates a reviewed participation" do
      participation = FactoryBot.create(:assessment_participation, :reviewed)
      expect(participation.status).to eq("reviewed")
      expect(participation.graded_at).to be_present
    end
  end

  describe "validations" do
    let(:assessment) { FactoryBot.create(:assessment) }

    it "requires user to be unique per assessment" do
      user = FactoryBot.create(:confirmed_user)
      FactoryBot.create(:assessment_participation, assessment: assessment, user: user)

      duplicate = FactoryBot.build(:assessment_participation, assessment: assessment,
                                                              user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "enums" do
    it "supports all status values" do
      statuses = ["pending", "reviewed", "absent", "exempt"]
      statuses.each do |status|
        participation = FactoryBot.build(:assessment_participation, status: status)
        expect(participation.status).to eq(status)
      end
    end
  end

  describe ".tutorial_for" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:tutorial) { FactoryBot.create(:tutorial, lecture: lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    it "returns the tutorial_id for a user enrolled in the lecture" do
      TutorialMembership.create!(user: user, tutorial: tutorial)

      result = described_class.tutorial_for(user, lecture)
      expect(result).to eq(tutorial.id)
    end

    it "returns nil when the user has no tutorial membership" do
      result = described_class.tutorial_for(user, lecture)
      expect(result).to be_nil
    end
  end

  describe "performance record recomputation" do
    let(:participation) { FactoryBot.create(:assessment_participation) }
    let(:service) do
      instance_double(StudentPerformance::ComputationService,
                      compute_and_upsert_record_for: true)
    end

    before do
      allow(StudentPerformance::ComputationService)
        .to receive(:new)
        .with(lecture: participation.assessment.lecture)
        .and_return(service)
    end

    it "is gated by the assessment_grading flag" do
      Flipper.disable(:assessment_grading)

      participation.send(:recompute_performance_record)

      expect(service).not_to have_received(:compute_and_upsert_record_for)
    end
  end
end
