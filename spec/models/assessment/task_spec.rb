require "rails_helper"

RSpec.describe(Assessment::Task, type: :model) do
  describe "factory" do
    it "creates a valid default task" do
      task = FactoryBot.create(:assessment_task)
      expect(task).to be_valid
      expect(task.assessment.requires_points).to be(true)
      expect(task.max_points).to be > 0
    end
  end

  describe "validations" do
    it "requires a title" do
      task = FactoryBot.build(:assessment_task, title: nil)
      expect(task).not_to be_valid
      expect(task.errors[:title]).to be_present
    end

    it "requires max_points to be >= 0" do
      task = FactoryBot.build(:assessment_task, max_points: -1)
      expect(task).not_to be_valid
      expect(task.errors[:max_points]).to be_present
    end

    it "accepts max_points = 0" do
      task = FactoryBot.build(:assessment_task, max_points: 0)
      expect(task).to be_valid
    end

    context "when assessment requires points" do
      let(:assessment) { FactoryBot.create(:assessment, requires_points: true) }

      it "is valid" do
        task = FactoryBot.build(:assessment_task, assessment: assessment)
        expect(task).to be_valid
      end
    end

    context "when assessment does not require points" do
      let(:assessment) { FactoryBot.create(:assessment, requires_points: false) }

      it "is invalid" do
        task = FactoryBot.build(:assessment_task, assessment: assessment)
        expect(task).not_to be_valid
        expect(task.errors[:base]).to include(
          I18n.t("activerecord.errors.models.assessment/task.attributes.base.requires_points_true")
        )
      end
    end
  end

  describe "acts_as_list" do
    let(:assessment) { FactoryBot.create(:assessment, requires_points: true) }

    it "manages position automatically" do
      task1 = FactoryBot.create(:assessment_task, assessment: assessment)
      task2 = FactoryBot.create(:assessment_task, assessment: assessment)
      task3 = FactoryBot.create(:assessment_task, assessment: assessment)

      expect(task1.reload.position).to eq(1)
      expect(task2.reload.position).to eq(2)
      expect(task3.reload.position).to eq(3)
    end
  end
end
