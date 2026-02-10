require "rails_helper"

RSpec.describe(GradeTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  context "with an assignment" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessment: assessment) }

    context "when no participations are reviewed" do
      before do
        create(:assessment_participation, :submitted,
               assessment: assessment, tutorial: tutorial)
      end

      it "renders the empty state" do
        render_inline(component)
        expect(rendered_content).to include(I18n.t("assessment.no_grades_yet"))
      end

      it "reports any_reviewed? as false" do
        expect(component.any_reviewed?).to be(false)
      end
    end
  end

  context "with an exam (gradable)" do
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) do
      exam.ensure_gradebook!
      exam.assessment
    end
    let(:component) { described_class.new(assessment: assessment) }

    context "when participations have grades" do
      let(:grader) { create(:confirmed_user) }
      let!(:reviewed_participation) do
        create(:assessment_participation, :reviewed,
               assessment: assessment, tutorial: tutorial,
               grader: grader, grade_numeric: 2.3, grade_text: "2.3")
      end

      it "renders a table with the reviewed participation" do
        render_inline(component)
        expect(rendered_content).to include("2.3")
        expect(rendered_content).to include(reviewed_participation.user.tutorial_name)
      end

      it "reports any_reviewed? as true" do
        expect(component.any_reviewed?).to be(true)
      end

      it "returns the grade display" do
        expect(component.grade_display(reviewed_participation)).to eq("2.3")
      end

      it "returns the grader display" do
        expect(component.grader_display(reviewed_participation)).to eq(grader.tutorial_name)
      end

      it "returns the graded_at display" do
        expect(component.graded_at_display(reviewed_participation)).to eq(
          I18n.l(reviewed_participation.graded_at, format: :short)
        )
      end
    end

    context "with mixed participation statuses" do
      before do
        create(:assessment_participation, :submitted,
               assessment: assessment, tutorial: tutorial)
        create(:assessment_participation, :reviewed,
               assessment: assessment, tutorial: tutorial,
               grade_numeric: 1.7, grade_text: "1.7")
      end

      it "only shows reviewed participations in the table" do
        render_inline(component)
        expect(component.reviewed_participations.count).to eq(1)
      end
    end
  end

  describe "#grade_display" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessment: assessment) }

    it "returns nil when grade_numeric is nil" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       grade_numeric: nil)
      expect(component.grade_display(participation)).to be_nil
    end

    it "shows combined display when grade_text differs from numeric" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       grade_numeric: 4.0,
                                                       grade_text: "ausreichend")
      expect(component.grade_display(participation)).to eq("4.0 (ausreichend)")
    end
  end
end
