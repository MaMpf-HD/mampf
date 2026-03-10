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
      expect(participation.submitted_at).to be_present
    end

    it "creates a reviewed participation" do
      participation = FactoryBot.create(:assessment_participation, :reviewed)
      expect(participation.status).to eq("reviewed")
      expect(participation.graded_at).to be_present
    end

    it "creates a participation with numeric grade" do
      participation = FactoryBot.create(:assessment_participation, :with_numeric_grade)
      expect([1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0,
              5.0]).to include(participation.grade_numeric)
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

    context "grade_numeric validation" do
      let(:gradable_assessment) { FactoryBot.create(:assessment, :gradable) }

      it "accepts valid German grades on gradable assessments" do
        valid_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]
        valid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           assessment: gradable_assessment,
                                           grade_numeric: grade)
          expect(participation).to be_valid
        end
      end

      it "rejects invalid grades" do
        invalid_grades = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.0]
        invalid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           assessment: gradable_assessment,
                                           grade_numeric: grade)
          expect(participation).not_to be_valid
          expect(participation.errors[:grade_numeric]).to be_present
        end
      end

      it "rejects grade_numeric on non-gradable assessments" do
        participation = FactoryBot.build(:assessment_participation,
                                         assessment: assessment,
                                         grade_numeric: 1.0)
        expect(participation).not_to be_valid
        expect(participation.errors[:grade_numeric]).to be_present
      end

      it "allows nil" do
        participation = FactoryBot.build(:assessment_participation, grade_numeric: nil)
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

  describe "achievement recomputation trigger" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    before do
      Flipper.enable(:assessment_grading)
      FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
    end

    after { Flipper.disable(:assessment_grading) }

    context "when grade_text changes on an achievement participation" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "enqueues PerformanceRecordUpdateJob" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)

        expect(PerformanceRecordUpdateJob).to receive(:perform_async)
          .with(lecture.id, user.id)

        participation.update!(grade_text: "pass")
      end
    end

    context "when grade_text changes on a non-achievement participation" do
      let(:assignment) do
        FactoryBot.create(:assignment, :with_lecture, lecture: lecture)
      end
      let(:assessment) do
        FactoryBot.create(:assessment, assessable: assignment,
                                       lecture: lecture)
      end
      let!(:participation) do
        FactoryBot.create(:assessment_participation,
                          assessment: assessment, user: user)
      end

      it "does not enqueue PerformanceRecordUpdateJob" do
        expect(PerformanceRecordUpdateJob).not_to receive(:perform_async)

        participation.update!(grade_text: "some value")
      end
    end

    context "when a non-grade_text attribute changes" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "does not enqueue PerformanceRecordUpdateJob" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)

        expect(PerformanceRecordUpdateJob).not_to receive(:perform_async)

        participation.update!(status: :reviewed)
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
