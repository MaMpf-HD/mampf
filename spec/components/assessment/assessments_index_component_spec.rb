require "rails_helper"

RSpec.describe(AssessmentsIndexComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }

  before do
    Flipper.enable(:assessment_grading)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  context "with a lecture" do
    let(:lecture) { create(:lecture, teacher: teacher) }

    it "includes assignments" do
      create(:valid_assignment, lecture: lecture, title: "Assignment 1")
      component = described_class.new(lecture: lecture)
      render_inline(component)
      expect(rendered_content).to include("Assignment 1")
    end
  end
end
