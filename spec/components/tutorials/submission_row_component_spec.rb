require "rails_helper"

RSpec.describe(SubmissionRowComponent, type: :component) do
  let(:tutor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }

  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end

  let(:submission) do
    create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
  end

  let(:component) do
    described_class.new(submission: submission, assignment: assignment, tutorial: tutorial,
                        mode: "tutor")
  end

  before do
    assignment.reload
    assessment.reload
    allow(vc_test_controller).to receive(:current_user).and_return(tutor)
  end

  describe "#row_id" do
    it "returns the correct row id" do
      expect(component.row_id).to eq("submission-row-#{submission.id}")
    end
  end

  describe "#late?" do
    context "when submission is not late" do
      it "returns false" do
        allow(submission).to receive(:too_late?).and_return(false)
        expect(component.late?).to eq(false)
      end
    end

    context "when submission is late" do
      it "returns true" do
        allow(submission).to receive(:too_late?).and_return(true)
        expect(component.late?).to eq(true)
      end
    end
  end

  describe "#grading_enabled?" do
    context "when flipper is disabled" do
      before { Flipper.disable(:assessment_grading) }

      it "returns false" do
        expect(component.grading_enabled?).to eq(false)
      end
    end

    context "when flipper is enabled and assignment is assessable" do
      before do
        Flipper.enable(:assessment_grading)
        allow(assignment).to receive(:assessable?).and_return(true)
      end
      after { Flipper.disable(:assessment_grading) }

      it "returns true" do
        expect(component.grading_enabled?).to eq(true)
      end
    end
  end

  describe "#allow_grading?" do
    context "when assignment is active" do
      before { allow(assignment).to receive(:active?).and_return(true) }

      it "returns false" do
        expect(component.allow_grading?).to eq(false)
      end
    end

    context "when assignment is not active" do
      before { allow(assignment).to receive(:active?).and_return(false) }

      it "returns true" do
        expect(component.allow_grading?).to eq(true)
      end
    end
  end

  describe "#tasks" do
    it "returns persisted tasks from assignment assessment" do
      assessment
      expect(component.tasks).to eq(assignment.assessment.persisted_tasks)
    end

    context "when assessment has no persisted tasks" do
      before { allow(assignment.assessment).to receive(:persisted_tasks).and_return(nil) }

      it "returns an empty array" do
        expect(component.tasks).to eq([])
      end
    end
  end

  describe "#extract_task_points" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment) }

    context "when task points exist for submission" do
      it "returns the points" do
        graded_task = double("graded_task", task_id: task.id, points: 8.0)
        allow(submission).to receive(:graded_tasks_points).and_return([graded_task])
        expect(component.extract_task_points(task)).to eq(8.0)
      end
    end

    context "when no task points exist for submission" do
      it "returns nil" do
        allow(submission).to receive(:graded_tasks_points).and_return([])
        expect(component.extract_task_points(task)).to be_nil
      end
    end
  end

  describe "#badge_status_participation_color" do
    it "returns warning for pending" do
      expect(component.badge_status_participation_color(:pending)).to eq("warning")
    end

    it "returns success for reviewed" do
      expect(component.badge_status_participation_color(:reviewed)).to eq("success")
    end

    it "returns info for exempt" do
      expect(component.badge_status_participation_color(:exempt)).to eq("info")
    end

    it "returns info for absent" do
      expect(component.badge_status_participation_color(:absent)).to eq("info")
    end

    it "returns nil for unknown status" do
      expect(component.badge_status_participation_color(:unknown)).to be_nil
    end
  end

  describe "#badge_status_participation_class" do
    it "returns correct class string" do
      expect(component.badge_status_participation_class(:pending))
        .to eq("badge rounded-pill bg-warning")
    end
  end

  describe "#task_points_input" do
    let!(:task) { create(:assessment_task, assessment: assignment.assessment, max_points: 10) }

    it "renders an input with the task's id in the name" do
      html = component.task_points_input(task, true)
      expect(html).to include("task_points[#{task.id}]")
    end

    it "sets the value to the extracted task points" do
      allow(component).to receive(:extract_task_points).with(task).and_return(6.5)
      html = component.task_points_input(task, true)
      expect(html).to include('value="6.5"')
    end

    context "when grading is not allowed" do
      it "disables the input" do
        html = component.task_points_input(task, false)
        expect(html).to include("disabled")
      end
    end

    context "when grading is allowed" do
      it "does not disable the input" do
        html = component.task_points_input(task, true)
        expect(html).not_to include("disabled")
      end
    end
  end

  describe "#save_row_button" do
    before { render_inline(component) }

    it "renders a button with the save icon" do
      html = component.save_row_button(true)
      expect(html).to include("bi-save")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component.save_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#refresh_row_button" do
    before { render_inline(component) }

    it "renders a button with the refresh icon" do
      html = component.refresh_row_button(true)
      expect(html).to include("bi-arrow-clockwise")
    end

    context "when grading is not allowed" do
      it "disables the button" do
        html = component.refresh_row_button(false)
        expect(html).to include("disabled")
      end
    end
  end

  describe "#late_submission_info" do
    before { render_inline(component) }
    context "when submission decision is already made (accepted is not nil)" do
      before { allow(submission).to receive(:accepted).and_return(true) }

      it "returns just the late text" do
        expect(component.late_submission_info(submission, tutorial))
          .to eq(component.send(:t, "submission.late"))
      end
    end

    context "when submission decision is pending and current_user is a tutor of the tutorial" do
      before do
        allow(submission).to receive(:accepted).and_return(nil)
        tutorial.tutors << tutor
      end

      it "includes the late-submission-decision hint" do
        result = component.late_submission_info(submission, tutorial)
        expect(result).to include(component.send(:t, "tutorial.late_submission_decision"))
      end
    end

    context "when submission decision is pending but current_user is not a tutor" do
      before { allow(submission).to receive(:accepted).and_return(nil) }

      it "returns just the late text" do
        expect(component.late_submission_info(submission, tutorial))
          .to eq(component.send(:t, "submission.late"))
      end
    end
  end

  describe "#can_grade?" do
    before { render_inline(component) }
    context "when current_user is an admin" do
      before { allow(tutor).to receive(:admin?).and_return(true) }

      it "returns true" do
        expect(component.can_grade?).to eq(true)
      end
    end

    context "when current_user is not an admin but can grade in scope" do
      before do
        allow(tutor).to receive(:admin?).and_return(false)
        allow(tutor).to receive(:can_grade_in_scope?).with(tutorial).and_return(true)
      end

      it "returns true" do
        expect(component.can_grade?).to eq(true)
      end
    end

    context "when current_user is not an admin and cannot grade in scope" do
      before do
        allow(tutor).to receive(:admin?).and_return(false)
        allow(tutor).to receive(:can_grade_in_scope?).with(tutorial).and_return(false)
      end

      it "returns false" do
        expect(component.can_grade?).to eq(false)
      end
    end
  end

  describe "rendering" do
    before { assessment }

    it "renders the submission row" do
      render_inline(component)
      expect(rendered_content).to include("submission-row-#{submission.id}")
    end
  end
end
