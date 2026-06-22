require "rails_helper"

RSpec.describe(TutorialGradingTableComponent, type: :component) do
  let(:lecture) { create(:lecture) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let!(:assignment) do
    create(:assignment, :with_lecture, lecture: lecture, deadline: 1.hour.from_now)
  end
  let!(:assessment) do
    create(:assessment, requires_points: true, assessable: assignment, lecture: lecture)
  end
  let(:stack) { [] }
  let(:non_submitters) { [] }
  let(:component) do
    described_class.new(assignment: assignment, tutorial: tutorial,
                        stack: stack, non_submitters: non_submitters)
  end

  before do
    assignment.reload
    assessment.reload
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

  describe "#tasks" do
    let!(:task) { create(:assessment_task, assessment: assessment) }

    it "returns tasks from assignment assessment" do
      expect(component.tasks).to eq(assignment.reload.assessment.tasks)
    end
  end

  describe "#total_max_points" do
    context "when there are no tasks" do
      it "returns 0" do
        expect(component.total_max_points).to eq(0)
      end
    end

    context "when there are tasks with max_points" do
      before do
        create(:assessment_task, assessment: assessment, max_points: 10)
        create(:assessment_task, assessment: assessment, max_points: 5)
        assignment.reload
      end

      it "returns the sum of max points" do
        expect(component.total_max_points).to eq(15)
      end
    end
  end

  describe "rendering" do
    it "renders the grading table" do
      render_inline(component)
      expect(rendered_content).to include("grading-table")
    end
  end
end
