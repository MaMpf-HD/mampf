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
    described_class.new(submission: submission, assignment: assignment, tutorial: tutorial)
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
    it "returns tasks from assignment assessment" do
      assessment
      expect(component.tasks).to eq(assignment.assessment.tasks)
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

  describe "rendering" do
    before { assessment }

    it "renders the submission row" do
      render_inline(component)
      expect(rendered_content).to include("submission-row-#{submission.id}")
    end
  end
end
