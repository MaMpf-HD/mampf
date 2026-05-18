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

  describe "#points_entered?" do
    let(:assessment) { FactoryBot.create(:assessment, :gradable, requires_points: true) }
    let(:task) { FactoryBot.create(:assessment_task, assessment: assessment) }

    it "returns false when no task points exist" do
      expect(task.points_entered?).to be(false)
    end

    it "returns false when task points exist but all have nil points" do
      FactoryBot.create(:assessment_task_point, task: task, points: nil)
      expect(task.points_entered?).to be(false)
    end

    it "returns true when a task point with non-nil points exists" do
      FactoryBot.create(:assessment_task_point, task: task, points: 5)
      expect(task.points_entered?).to be(true)
    end

    it "returns true when a task point with zero points exists" do
      FactoryBot.create(:assessment_task_point, task: task, points: 0)
      expect(task.points_entered?).to be(true)
    end
  end

  describe "destruction" do
    let(:assessment) { FactoryBot.create(:assessment, :gradable, requires_points: true) }
    let(:task) { FactoryBot.create(:assessment_task, assessment: assessment) }

    it "can be destroyed when no points have been entered" do
      expect(task.destroy).to be_truthy
      expect(Assessment::Task.find_by(id: task.id)).to be_nil
    end

    it "can be destroyed when only nil-points task points exist" do
      FactoryBot.create(:assessment_task_point, task: task, points: nil)
      expect(task.destroy).to be_truthy
      expect(Assessment::Task.find_by(id: task.id)).to be_nil
    end

    it "cannot be destroyed when points have been entered" do
      FactoryBot.create(:assessment_task_point, task: task, points: 8)
      expect(task.destroy).to be(false)
      expect(task.reload).to be_persisted
    end

    it "preserves task points when destruction is blocked" do
      tp = FactoryBot.create(:assessment_task_point, task: task, points: 8)
      task.destroy
      expect(Assessment::TaskPoint.find_by(id: tp.id)).to be_present
    end

    context "when assignment deadline has passed" do
      let!(:assignment) do
        FactoryBot.create(:assignment, :with_lecture,
                          deadline: 1.hour.from_now)
      end
      let!(:assessment) do
        FactoryBot.create(:assessment,
                          requires_points: true,
                          assessable: assignment,
                          lecture: assignment.lecture)
      end
      let!(:past_deadline_task) do
        FactoryBot.create(:assessment_task, assessment: assessment)
      end

      before { Timecop.travel(2.hours.from_now) }
      after { Timecop.return }

      it "cannot be destroyed" do
        expect(past_deadline_task.destroy).to be(false)
        expect(past_deadline_task.reload).to be_persisted
      end

      it "reports deadline_passed? as true" do
        expect(past_deadline_task.deadline_passed?).to be(true)
      end
    end

    context "when assignment deadline has not passed" do
      it "reports deadline_passed? as false" do
        expect(task.deadline_passed?).to be(false)
      end
    end
  end

  describe "performance record recomputation" do
    before { Flipper.enable(:assessment_grading) }

    after { Flipper.disable(:assessment_grading) }

    let(:task) { FactoryBot.create(:assessment_task) }
    let(:create_existing_record) { true }
    let!(:record) do
      next unless create_existing_record

      FactoryBot.create(:student_performance_record,
                        lecture: task.assessment.lecture)
    end
    let(:service) do
      instance_double(StudentPerformance::ComputationService,
                      compute_and_upsert_all_records!: true)
    end

    before do
      allow(StudentPerformance::ComputationService)
        .to receive(:new)
        .with(lecture: task.assessment.lecture)
        .and_return(service)
    end

    it "is gated by the assessment_grading flag" do
      Flipper.disable(:assessment_grading)

      task.send(:recompute_all_performance_records)

      expect(service).not_to have_received(:compute_and_upsert_all_records!)
    end

    context "when no performance records exist yet" do
      let(:create_existing_record) { false }

      it "still recomputes all performance records" do
        task.send(:recompute_all_performance_records)

        expect(service).to have_received(:compute_and_upsert_all_records!)
      end
    end
  end
end
