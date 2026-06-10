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

  context "when assignment is ready to be pointed" do
    let!(:user) { FactoryBot.create(:confirmed_user) }
    let!(:assignment) do
      FactoryBot.create(:valid_assignment, deadline: 1.hour.from_now)
    end
    let!(:assessment) do
      FactoryBot.create(:assessment, assessable: assignment, requires_points: true)
    end
    let!(:task1) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:task3) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:participation) do
      FactoryBot.create(:assessment_participation,
                        assessment: assessment, user: user,
                        status: :pending,
                        points_total: nil)
    end

    before do
      Timecop.travel(2.hours.from_now)
    end
    after { Timecop.return }

    context "when some tasks are scored and some are not" do
      before do
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task1,
                          points: 5.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task2,
                          points: nil)
      end
      describe "recompute_points_total!" do
        it "updates points_total to the sum of task points" do
          participation.recompute_points_total!
          expect(participation.points_total).to eq(5)
        end
      end
      describe "update_status_if_all_scored!" do
        it "if current status is pending, still keeps the status as pending" do
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("pending")
        end
        it "if current status is reviewed, changes the status to pending" do
          participation.update!(status: :reviewed)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("pending")
        end
        it "if current status is absent, keeps the status as absent" do
          participation.update!(status: :absent)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("absent")
        end
        it "if current status is exempt, keeps the status as exempt" do
          participation.update!(status: :exempt)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("exempt")
        end
      end
    end

    context "when all tasks are scored" do
      before do
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task1,
                          points: 5.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task2,
                          points: 3.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task3,
                          points: 10.0)
      end
      describe "recompute_points_total!" do
        it "updates points_total to the sum of task points" do
          participation.recompute_points_total!
          expect(participation.points_total).to eq(18)
        end
      end
      describe "update_status_if_all_scored!" do
        it "changes the status to reviewed" do
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("reviewed")
        end
        it "keeps the status as reviewed if already reviewed" do
          participation.update!(status: :reviewed)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("reviewed")
        end
        it "if current status is absent, keeps the status as absent" do
          participation.update!(status: :absent)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("absent")
        end
        it "if current status is exempt, keeps the status as exempt" do
          participation.update!(status: :exempt)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("exempt")
        end
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
