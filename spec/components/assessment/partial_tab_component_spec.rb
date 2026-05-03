require "rails_helper"

RSpec.describe(PartialTabComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  it "renders the given partial with locals" do
    assignment = create(:valid_assignment, lecture: lecture)
    assessment = assignment.reload.assessment
    component = described_class.new(
      partial: "assessment/assessments/settings",
      locals: { assessment: assessment, assessable: assignment,
                lecture: lecture }
    )
    render_inline(component)
    expect(rendered_content).to include("assessments--settings")
  end

  it "works without locals" do
    component = described_class.new(
      partial: "assessment/assessments/settings",
      locals: {}
    )
    expect { component }.not_to raise_error
  end
end
