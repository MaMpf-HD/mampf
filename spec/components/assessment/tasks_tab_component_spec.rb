require "rails_helper"

RSpec.describe(TasksTabComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:assignment) { create(:valid_assignment, lecture: lecture) }
  let(:assessment) { assignment.reload.assessment }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  context "when assessment is present" do
    let(:component) do
      described_class.new(
        assessment: assessment, assessable: assignment,
        tasks: assessment.tasks.order(:position), task: nil
      )
    end

    it "renders the tasks partial" do
      render_inline(component)
      expect(rendered_content).not_to include("alert-warning")
    end
  end

  context "when assessment is nil" do
    let(:component) do
      described_class.new(
        assessment: nil, assessable: assignment,
        tasks: [], task: nil
      )
    end

    it "renders the no-assessment warning" do
      render_inline(component)
      expect(rendered_content).to include("alert-warning")
      expect(rendered_content).to include(
        I18n.t("assessment.errors.no_assessment")
      )
    end

    it "renders the warning icon" do
      render_inline(component)
      expect(rendered_content).to include("bi-exclamation-triangle")
    end
  end
end
