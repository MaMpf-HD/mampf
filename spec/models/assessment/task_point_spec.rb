require "rails_helper"

RSpec.describe(Assessment::TaskPoint, type: :model) do
  describe "factory" do
    it "creates a valid default task point" do
      task_point = FactoryBot.create(:assessment_task_point)
      expect(task_point).to be_valid
    end

    it "creates a task point with grader" do
      task_point = FactoryBot.create(:assessment_task_point, :with_grader)
      expect(task_point.grader).to be_present
    end

    it "creates a task point with submission" do
      task_point = FactoryBot.create(:assessment_task_point, :with_submission)
      expect(task_point.submission).to be_present
    end

    it "creates a task point with bonus points" do
      task_point = FactoryBot.create(:assessment_task_point, :bonus_points)
      expect(task_point.points).to be > task_point.task.max_points
    end
  end

  describe "validations" do
    context "when task and participation belong to same assessment" do
      let(:assessment) { FactoryBot.create(:assessment, requires_points: true) }
      let(:task) { FactoryBot.create(:assessment_task, assessment: assessment) }
      let(:participation) { FactoryBot.create(:assessment_participation, assessment: assessment) }

      it "is valid" do
        task_point = FactoryBot.build(:assessment_task_point,
                                      task: task,
                                      assessment_participation: participation)
        expect(task_point).to be_valid
      end
    end

    context "when task and participation belong to different assessments" do
      let(:assessment1) { FactoryBot.create(:assessment, requires_points: true) }
      let(:assessment2) { FactoryBot.create(:assessment, requires_points: true) }
      let(:task) { FactoryBot.create(:assessment_task, assessment: assessment1) }
      let(:participation) { FactoryBot.create(:assessment_participation, assessment: assessment2) }

      it "is invalid" do
        task_point = FactoryBot.build(:assessment_task_point,
                                      task: task,
                                      assessment_participation: participation)
        expect(task_point).not_to be_valid
        expect(task_point.errors[:base]).to include(
          I18n.t("activerecord.errors.models.assessment/" \
                 "task_point.attributes.base.assessment_mismatch")
        )
      end
    end

    it "requires points >= 0" do
      task_point = FactoryBot.build(:assessment_task_point, points: -1)
      expect(task_point).not_to be_valid
      expect(task_point.errors[:points]).to be_present
    end

    it "accepts zero points" do
      task_point = FactoryBot.build(:assessment_task_point, points: 0)
      expect(task_point).to be_valid
    end

    it "accepts bonus points exceeding task maximum" do
      task_point = FactoryBot.build(:assessment_task_point)
      task_point.task.max_points = 10
      task_point.points = 12
      expect(task_point).to be_valid
    end

    it "allows nil points" do
      task_point = FactoryBot.build(:assessment_task_point, points: nil)
      expect(task_point).to be_valid
    end
  end
end
