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

    # The deadline on its own does not protect a task: a question that turns out
    # to be unsolvable has to be removable afterwards, and by then nobody will
    # have marked it.
    context "when the assignment deadline has passed" do
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

      # friendly_deadline is deadline plus the lecture's grace period, which is
      # what grading_open? keys off — entering points earlier would be refused.
      before { Timecop.travel(assignment.friendly_deadline + 1.minute) }
      after { Timecop.return }

      it "can still be destroyed while no points have been entered" do
        expect(past_deadline_task.destroy).to be_truthy
        expect(Assessment::Task.find_by(id: past_deadline_task.id)).to be_nil
      end

      it "cannot be destroyed once points have been entered" do
        FactoryBot.create(:assessment_task_point,
                          task: past_deadline_task, points: 8)

        expect(past_deadline_task.destroy).to be(false)
        expect(past_deadline_task.reload).to be_persisted
      end
    end
  end

  # Nothing stops a teacher from adding a task after grading has begun. The new
  # task has no points anywhere, so anyone who counted as fully marked no longer
  # is and has to go back into the tutor's queue.
  describe "adding a task once participations exist" do
    let(:assessment) { FactoryBot.create(:assessment, :gradable, requires_points: true) }
    let!(:existing_task) { FactoryBot.create(:assessment_task, assessment: assessment) }

    def add_a_task
      FactoryBot.create(:assessment_task, assessment: assessment)
    end

    it "sends a reviewed participation back to pending" do
      participation = FactoryBot.create(:assessment_participation, :reviewed,
                                        assessment: assessment)

      add_a_task

      expect(participation.reload).to be_pending
    end

    it "leaves an exempt participation alone" do
      participation = FactoryBot.create(:assessment_participation, :exempt,
                                        assessment: assessment)

      add_a_task

      expect(participation.reload).to be_exempt
    end

    it "leaves an absent participation alone" do
      participation = FactoryBot.create(:assessment_participation, :absent,
                                        assessment: assessment)

      add_a_task

      expect(participation.reload).to be_absent
    end

    it "does not reach into another assessment" do
      other = FactoryBot.create(:assessment, :gradable, requires_points: true)
      participation = FactoryBot.create(:assessment_participation, :reviewed,
                                        assessment: other)

      add_a_task

      expect(participation.reload).to be_reviewed
    end

    # Only a new task leaves something unscored; editing one does not.
    it "does not reopen when an existing task is edited" do
      participation = FactoryBot.create(:assessment_participation, :reviewed,
                                        assessment: assessment)

      existing_task.update!(max_points: 42)

      expect(participation.reload).to be_reviewed
    end

    it "reopens them all in one statement" do
      3.times do
        FactoryBot.create(:assessment_participation, :reviewed, assessment: assessment)
      end

      updates = 0
      subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        updates += 1 if payload[:sql].include?('UPDATE "assessment_participations"')
      end
      add_a_task
      ActiveSupport::Notifications.unsubscribe(subscription)

      expect(updates).to eq(1)
    end
  end
end
