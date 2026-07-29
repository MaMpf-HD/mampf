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

  describe "the grading lifecycle guard" do
    let(:grader) { FactoryBot.create(:confirmed_user) }

    context "while the assignment can still be submitted to" do
      # The default assignment factory puts the deadline 30 days out.
      let(:participation) { FactoryBot.create(:assessment_participation) }

      it "reports grading as closed" do
        expect(participation.assessment.grading_open?).to be(false)
      end

      it "rejects a points total" do
        participation.points_total = 12

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects a text grade" do
        participation.grade_text = "pass"

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects a grader and a grading timestamp" do
        participation.grader = grader
        participation.graded_at = Time.zone.now

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects leaving the pending status" do
        participation.status = :reviewed

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "allows changes that are not grading data" do
        participation.submitted_at = Time.zone.now

        expect(participation).to be_valid
      end
    end

    context "once the deadline and the grace period have passed" do
      let(:assessment) { FactoryBot.create(:assessment, :for_expired_assignment) }
      let(:participation) do
        FactoryBot.create(:assessment_participation, assessment: assessment)
      end

      it "reports grading as open" do
        expect(participation.assessment.grading_open?).to be(true)
      end

      it "accepts the write that was rejected before" do
        participation.points_total = 12
        participation.grader = grader
        participation.graded_at = Time.zone.now
        participation.status = :reviewed

        expect(participation).to be_valid
      end
    end

    context "with an assessable that never closes" do
      # Talk does not override grading_open?, so it keeps the default of true.
      let(:assessment) { FactoryBot.create(:assessment, :gradable) }
      let(:participation) do
        FactoryBot.create(:assessment_participation, assessment: assessment)
      end

      it "reports grading as open" do
        expect(participation.assessment.grading_open?).to be(true)
      end

      it "accepts grading data straight away" do
        participation.points_total = 12
        participation.status = :reviewed

        expect(participation).to be_valid
      end
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
end
