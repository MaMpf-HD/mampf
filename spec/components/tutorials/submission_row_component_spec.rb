require "rails_helper"

RSpec.describe(SubmissionRowComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:student2) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher, submission_grace_period: 70) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student],
                        created_at: assignment.deadline)
  end
  let(:late_rejected_submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student2],
                        created_at: assignment.deadline + 2.hours, accepted: false)
  end

  let(:component_tutorial) do
    described_class.new(submission: submission, assignment: assignment, grading_scope: tutorial)
  end
  let(:component_late_rejected) do
    described_class.new(submission: late_rejected_submission, assignment: assignment,
                        grading_scope: tutorial)
  end
  let(:component_lecture) do
    described_class.new(submission: submission, assignment: assignment, grading_scope: lecture)
  end

  before do
    assignment.reload
    assessment.reload
  end

  describe "#initialize" do
    context "when grading_scope is a Tutorial" do
      it "sets @mode to tutor" do
        expect(component_tutorial.instance_variable_get(:@mode)).to eq("tutor")
      end
    end

    context "when grading_scope is a Lecture" do
      it "sets @mode to teacher" do
        expect(component_lecture.instance_variable_get(:@mode)).to eq("teacher")
      end
    end
  end

  describe "#row_id" do
    it "returns the correct row id" do
      expect(component_tutorial.row_id).to eq("submission-row-#{submission.id}")
    end
  end

  describe "#late?" do
    context "when submission is not late" do
      it "returns false" do
        allow(submission).to receive(:too_late?).and_return(false)
        expect(component_tutorial.late?).to eq(false)
      end
    end

    context "when submission is late" do
      it "returns true" do
        allow(submission).to receive(:too_late?).and_return(true)
        expect(component_tutorial.late?).to eq(true)
      end
    end
  end

  describe "#grading_enabled?" do

    context "when flipper is enabled and assignment is assessable" do
      before do
        allow(assignment).to receive(:assessable?).and_return(true)
      end

      it "returns true" do
        expect(component_tutorial.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    context "before deadline" do
      it "returns false regardless of submission" do
        expect(component_tutorial.allow_grading?).to eq(false)
      end
    end

    context "after deadline and before grace period" do
      before { Timecop.travel(2.hours.from_now) }
      after { Timecop.return }

      it "returns false" do
        expect(component_tutorial.allow_grading?).to eq(false)
      end
    end

    context "after grace period" do
      before { Timecop.travel(3.hours.from_now) }
      after { Timecop.return }

      context "and submission is valid for pointing" do
        it "returns true" do
          expect(component_tutorial.allow_grading?).to eq(true)
        end
      end

      context "and submission is not valid for pointing" do
        it "returns false" do
          expect(component_late_rejected.allow_grading?).to eq(false)
        end
      end
    end
  end

  describe "#tasks" do
    it "returns persisted tasks from assignment assessment" do
      assessment
      expect(component_tutorial.tasks).to eq(assignment.assessment.persisted_tasks)
    end

    context "when assessment has no persisted tasks" do
      before { allow(assignment.assessment).to receive(:persisted_tasks).and_return(nil) }

      it "returns an empty array" do
        expect(component_tutorial.tasks).to eq([])
      end
    end
  end

  describe "#extract_task_points" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment) }

    context "when task points exist for submission" do
      it "returns the points" do
        graded_task = double("graded_task", task_id: task.id, points: 8.0)
        allow(submission).to receive(:graded_tasks_points).and_return([graded_task])
        expect(component_tutorial.extract_task_points(task)).to eq(8.0)
      end
    end

    context "when no task points exist for submission" do
      it "returns nil" do
        allow(submission).to receive(:graded_tasks_points).and_return([])
        expect(component_tutorial.extract_task_points(task)).to be_nil
      end
    end
  end

  describe "#badge_status_participation_color" do
    it "returns warning for pending" do
      expect(component_tutorial.badge_status_participation_color(:pending)).to eq("warning")
    end

    it "returns success for reviewed" do
      expect(component_tutorial.badge_status_participation_color(:reviewed)).to eq("success")
    end

    it "returns info for exempt" do
      expect(component_tutorial.badge_status_participation_color(:exempt)).to eq("info")
    end

    it "returns info for absent" do
      expect(component_tutorial.badge_status_participation_color(:absent)).to eq("info")
    end

    it "returns nil for unknown status" do
      expect(component_tutorial.badge_status_participation_color(:unknown)).to be_nil
    end
  end

  describe "#badge_status_participation_class" do
    it "returns correct class string" do
      expect(component_tutorial.badge_status_participation_class(:pending))
        .to eq("badge rounded-pill bg-warning")
    end
  end

  describe "#task_points_input" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment, max_points: 10) }

    it "renders an input with the task's id in the name" do
      html = component_tutorial.task_points_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    it "sets the value to the extracted task points" do
      allow(component_tutorial).to receive(:extract_task_points).with(task).and_return(6.5)
      html = component_tutorial.task_points_input(task, true)
      expect(html).to include('value="6.5"')
    end

    it "does not cap the input at the task's max_points, allowing bonus points" do
      html = component_tutorial.task_points_input(task, true)
      expect(html).not_to include("max=")
    end

    context "when grading is not allowed" do
      it "disables the input" do
        html = component_tutorial.task_points_input(task, false)
        expect(html).to include("disabled")
      end
    end

    context "when grading is allowed" do
      it "does not disable the input" do
        html = component_tutorial.task_points_input(task, true)
        expect(html).not_to include("disabled")
      end
    end
  end

  describe "#save_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "renders a button with the save icon" do
      html = component_tutorial.save_row_button(true)
      expect(html).to include("bi-save")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutorial.save_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#refresh_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "renders a button with the refresh icon" do
      html = component_tutorial.refresh_row_button(true)
      expect(html).to include("bi-arrow-clockwise")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutorial.refresh_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#late_submission_info" do
    context "when submission decision is already made (accepted is not nil)" do
      before do
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutorial)
        allow(submission).to receive(:accepted).and_return(true)
      end

      it "returns just the late text" do
        expect(component_tutorial.late_submission_info(submission, tutorial))
          .to eq(component_tutorial.send(:t, "submission.late"))
      end
    end

    context "when submission decision is pending and current_user is a tutor of the tutorial" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutorial)
      end

      it "includes the late-submission-decision hint" do
        result = component_tutorial.late_submission_info(submission, tutorial)
        expect(result).to include(component_tutorial.send(:t, "tutorial.late_submission_decision"))
      end
    end

    context "when submission decision is pending but current_user is not a tutor" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(student)
        render_inline(component_tutorial)
      end

      it "returns just the late text" do
        expect(component_tutorial.late_submission_info(submission, tutorial))
          .to eq(component_tutorial.send(:t, "submission.late"))
      end
    end
  end

  describe "#can_grade?" do
    context "when grading_scope is a Tutorial" do
      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_tutorial)
        end

        it "returns true" do
          expect(component_tutorial.can_grade?).to eq(true)
        end
      end

      context "when current_user is a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_tutorial)
        end
        it "returns true" do
          expect(component_tutorial.can_grade?).to eq(true)
        end
      end

      context "when current_user is a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_tutorial)
        end
        it "returns true" do
          expect(component_tutorial.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin and not a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_tutorial)
        end

        it "returns false" do
          expect(component_tutorial.can_grade?).to eq(false)
        end
      end
    end

    context "when grading_scope is a Lecture" do
      context "when current_user is a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_lecture)
        end

        it "returns true" do
          expect(component_lecture.can_grade?).to eq(true)
        end
      end

      context "when current_user is a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_lecture)
        end

        it "returns false" do
          expect(component_lecture.can_grade?).to eq(false)
        end
      end

      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_lecture)
        end

        it "returns true" do
          expect(component_lecture.can_grade?).to eq(true)
        end
      end
    end
  end

  describe "rendering" do
    before do
      submission
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutorial)
    end

    it "renders the submission row" do
      render_inline(component_tutorial)
      expect(rendered_content).to include("submission-row-#{submission.id}")
    end
  end
end
