require "rails_helper"

RSpec.describe(SubmissionRowComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:tutorial) { create(:tutorial, :with_tutor_by_id, tutor_id: tutor.id, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
  end

  let(:component_tutor) do
    described_class.new(submission: submission, assignment: assignment, tutorial: tutorial,
                        mode: "tutor")
  end
  let(:component_teacher) do
    described_class.new(submission: submission, assignment: assignment, tutorial: tutorial,
                        mode: "teacher")
  end

  before do
    assignment.reload
    assessment.reload
  end

  describe "#row_id" do
    it "returns the correct row id" do
      expect(component_tutor.row_id).to eq("submission-row-#{submission.id}")
    end
  end

  describe "#late?" do
    context "when submission is not late" do
      it "returns false" do
        allow(submission).to receive(:too_late?).and_return(false)
        expect(component_tutor.late?).to eq(false)
      end
    end

    context "when submission is late" do
      it "returns true" do
        allow(submission).to receive(:too_late?).and_return(true)
        expect(component_tutor.late?).to eq(true)
      end
    end
  end

  describe "#grading_enabled?" do
    context "when flipper is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "returns false" do
        expect(component_tutor.grading_enabled?).to eq(false)
      end
    end

    context "when flipper is enabled and assignment is assessable" do
      before do
        Flipper.enable(:assessment_grading)
        allow(assignment).to receive(:assessable?).and_return(true)
      end
      after { Flipper.disable(:assessment_grading) }

      it "returns true" do
        expect(component_tutor.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    context "when assignment is active" do
      before { allow(assignment).to receive(:active?).and_return(true) }

      it "returns false" do
        expect(component_tutor.allow_grading?).to eq(false)
      end
    end

    context "when assignment is not active" do
      before { allow(assignment).to receive(:active?).and_return(false) }

      it "returns true" do
        expect(component_tutor.allow_grading?).to eq(true)
      end
    end
  end

  describe "#tasks" do
    it "returns persisted tasks from assignment assessment" do
      assessment
      expect(component_tutor.tasks).to eq(assignment.assessment.persisted_tasks)
    end

    context "when assessment has no persisted tasks" do
      before { allow(assignment.assessment).to receive(:persisted_tasks).and_return(nil) }

      it "returns an empty array" do
        expect(component_tutor.tasks).to eq([])
      end
    end
  end

  describe "#extract_task_points" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment) }

    context "when task points exist for submission" do
      it "returns the points" do
        graded_task = double("graded_task", task_id: task.id, points: 8.0)
        allow(submission).to receive(:graded_tasks_points).and_return([graded_task])
        expect(component_tutor.extract_task_points(task)).to eq(8.0)
      end
    end

    context "when no task points exist for submission" do
      it "returns nil" do
        allow(submission).to receive(:graded_tasks_points).and_return([])
        expect(component_tutor.extract_task_points(task)).to be_nil
      end
    end
  end

  describe "#badge_status_participation_color" do
    it "returns warning for pending" do
      expect(component_tutor.badge_status_participation_color(:pending)).to eq("warning")
    end

    it "returns success for reviewed" do
      expect(component_tutor.badge_status_participation_color(:reviewed)).to eq("success")
    end

    it "returns info for exempt" do
      expect(component_tutor.badge_status_participation_color(:exempt)).to eq("info")
    end

    it "returns info for absent" do
      expect(component_tutor.badge_status_participation_color(:absent)).to eq("info")
    end

    it "returns nil for unknown status" do
      expect(component_tutor.badge_status_participation_color(:unknown)).to be_nil
    end
  end

  describe "#badge_status_participation_class" do
    it "returns correct class string" do
      expect(component_tutor.badge_status_participation_class(:pending))
        .to eq("badge rounded-pill bg-warning")
    end
  end

  describe "#task_points_input" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment, max_points: 10) }

    it "renders an input with the task's id in the name" do
      html = component_tutor.task_points_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    it "sets the value to the extracted task points" do
      allow(component_tutor).to receive(:extract_task_points).with(task).and_return(6.5)
      html = component_tutor.task_points_input(task, true)
      expect(html).to include('value="6.5"')
    end

    context "when grading is not allowed" do
      it "disables the input" do
        html = component_tutor.task_points_input(task, false)
        expect(html).to include("disabled")
      end
    end

    context "when grading is allowed" do
      it "does not disable the input" do
        html = component_tutor.task_points_input(task, true)
        expect(html).not_to include("disabled")
      end
    end
  end

  describe "#save_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders a button with the save icon" do
      html = component_tutor.save_row_button(true)
      expect(html).to include("bi-save")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutor.save_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#refresh_row_button" do
    before do
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders a button with the refresh icon" do
      html = component_tutor.refresh_row_button(true)
      expect(html).to include("bi-arrow-clockwise")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component_tutor.refresh_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#late_submission_info" do
    context "when submission decision is already made (accepted is not nil)" do
      before do
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutor)
        allow(submission).to receive(:accepted).and_return(true)
      end

      it "returns just the late text" do
        expect(component_tutor.late_submission_info(submission, tutorial))
          .to eq(component_tutor.send(:t, "submission.late"))
      end
    end

    context "when submission decision is pending and current_user is a tutor of the tutorial" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(tutor)
        render_inline(component_tutor)
      end

      it "includes the late-submission-decision hint" do
        result = component_tutor.late_submission_info(submission, tutorial)
        expect(result).to include(component_tutor.send(:t, "tutorial.late_submission_decision"))
      end
    end

    context "when submission decision is pending but current_user is not a tutor" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        allow(vc_test_controller).to receive(:current_user).and_return(student)
        render_inline(component_tutor)
      end

      it "returns just the late text" do
        expect(component_tutor.late_submission_info(submission, tutorial))
          .to eq(component_tutor.send(:t, "submission.late"))
      end
    end
  end

  describe "#can_grade?" do
    context "when mode is tutor" do
      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_tutor)
        end

        it "returns true" do
          expect(component_tutor.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin but a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(tutor)
          render_inline(component_tutor)
        end
        it "returns true" do
          expect(component_tutor.can_grade?).to eq(true)
        end
      end

      context "when current_user is not an admin and not a tutor" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(student)
          render_inline(component_tutor)
        end

        it "returns false" do
          expect(component_tutor.can_grade?).to eq(false)
        end
      end
    end

    context "when mode is teacher" do
      context "when current_user is not an admin but a teacher" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(teacher)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_grade?).to eq(true)
        end
      end

      context "when current_user is an admin" do
        before do
          allow(vc_test_controller).to receive(:current_user).and_return(admin)
          render_inline(component_teacher)
        end

        it "returns true" do
          expect(component_teacher.can_grade?).to eq(true)
        end
      end
    end
  end

  describe "rendering" do
    before do
      submission
      allow(vc_test_controller).to receive(:current_user).and_return(tutor)
      render_inline(component_tutor)
    end

    it "renders the submission row" do
      render_inline(component_tutor)
      expect(rendered_content).to include("submission-row-#{submission.id}")
    end
  end
end
