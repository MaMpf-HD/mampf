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

    context "when no participations exist" do
      it "renders the empty state" do
        render_inline(component)
        expect(rendered_content).to include(I18n.t("assessment.no_grades_yet"))
      end

      it "reports any_gradeable? as false" do
        expect(component.any_gradeable?).to be(false)
      end
    end

    context "when a pending participation exists" do
      before do
        create(:assessment_participation, :submitted,
               assessment: assessment, tutorial: tutorial)
      end

      it "renders the table (not the empty state)" do
        render_inline(component)
        expect(rendered_content).not_to include(
          I18n.t("assessment.no_grades_yet")
        )
      end

      it "shows em-dash for the grade" do
        render_inline(component)
        expect(rendered_content).to include("\u2014")
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

      it "reports any_gradeable? as true" do
        expect(component.any_gradeable?).to be(true)
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

    context "with an absent participation" do
      let!(:absent_participation) do
        create(:assessment_participation, :absent,
               assessment: assessment, tutorial: tutorial)
      end

      it "does not include absent in the main table" do
        expect(component.gradeable_participations).to be_empty
      end

      it "lists absent in the summary section" do
        render_inline(component)
        expect(rendered_content).to include(
          absent_participation.user.tutorial_name
        )
        expect(rendered_content).to include("5.0")
      end

      it "reports any_excluded? as true" do
        expect(component.any_excluded?).to be(true)
      end

      it "counts absent participations" do
        expect(component.absent_participations.count).to eq(1)
      end
    end

    context "with an exempt participation" do
      let!(:exempt_participation) do
        create(:assessment_participation, :exempt,
               assessment: assessment, tutorial: tutorial)
      end

      it "does not include exempt in the main table" do
        expect(component.gradeable_participations).to be_empty
      end

      it "lists exempt in the summary section" do
        render_inline(component)
        expect(rendered_content).to include(
          exempt_participation.user.tutorial_name
        )
        expect(rendered_content).to include("&mdash;")
      end

      it "reports any_excluded? as true" do
        expect(component.any_excluded?).to be(true)
      end

      it "counts exempt participations" do
        expect(component.exempt_participations.count).to eq(1)
      end
    end

    context "with mixed participation statuses" do
      let!(:pending) do
        create(:assessment_participation, :submitted,
               assessment: assessment, tutorial: tutorial)
      end
      let!(:reviewed) do
        create(:assessment_participation, :reviewed,
               assessment: assessment, tutorial: tutorial,
               grade_numeric: 1.7, grade_text: "1.7")
      end
      let!(:absent) do
        create(:assessment_participation, :absent,
               assessment: assessment, tutorial: tutorial)
      end

      it "includes only pending and reviewed in gradeable" do
        expect(component.gradeable_participations.count).to eq(2)
      end

      it "separates absent into excluded list" do
        expect(component.absent_participations.count).to eq(1)
      end

      it "renders both table and summary" do
        render_inline(component)
        expect(rendered_content).to include("1.7")
        expect(rendered_content).to include("5.0")
      end
    end
  end

  describe "#show_points_column?" do
    context "with an exam (pointable + gradable)" do
      let(:exam) { create(:exam, lecture: lecture) }
      let(:assessment) do
        exam.ensure_gradebook!
        exam.assessment
      end
      let(:component) { described_class.new(assessment: assessment) }

      it "returns true" do
        expect(component.show_points_column?).to be(true)
      end
    end

    context "with an assignment (pointable only)" do
      let(:assignment) { create(:valid_assignment, lecture: lecture) }
      let(:assessment) { assignment.reload.assessment }
      let(:component) { described_class.new(assessment: assessment) }

      it "returns false" do
        expect(component.show_points_column?).to be(false)
      end
    end

    context "with a talk (gradable only)" do
      let(:seminar) { create(:seminar) }
      let(:talk) { create(:talk, lecture: seminar) }
      let(:assessment) do
        talk.ensure_gradebook!
        talk.assessment
      end
      let(:component) { described_class.new(assessment: assessment) }

      it "returns false" do
        expect(component.show_points_column?).to be(false)
      end
    end
  end

  describe "#points_display" do
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) do
      exam.ensure_gradebook!
      exam.assessment
    end
    let(:component) { described_class.new(assessment: assessment) }

    it "returns em-dash when points_total is nil" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       points_total: nil)
      expect(component.points_display(participation)).to eq("\u2014")
    end

    it "returns the points as string when present" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       points_total: 42.5)
      expect(component.points_display(participation)).to eq("42.5")
    end
  end

  describe "points column rendering" do
    context "with an exam" do
      let(:exam) { create(:exam, lecture: lecture) }
      let(:assessment) do
        exam.ensure_gradebook!
        exam.assessment
      end
      let(:component) { described_class.new(assessment: assessment) }

      it "renders the points header" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, tutorial: tutorial,
               points_total: 80, grade_numeric: 1.7)
        render_inline(component)
        expect(rendered_content).to include(I18n.t("assessment.points"))
      end

      it "renders the points value in the row" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, tutorial: tutorial,
               points_total: 80, grade_numeric: 1.7)
        render_inline(component)
        expect(rendered_content).to include("80.0")
      end
    end

    context "with an assignment" do
      let(:assignment) { create(:valid_assignment, lecture: lecture) }
      let(:assessment) { assignment.reload.assessment }
      let(:component) { described_class.new(assessment: assessment) }

      it "does not render the points header" do
        create(:assessment_participation, :submitted,
               assessment: assessment, tutorial: tutorial)
        render_inline(component)
        expect(rendered_content).not_to include(I18n.t("assessment.points"))
      end
    end
  end

  describe "#grade_display" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessment: assessment) }

    it "returns em-dash when grade_numeric is nil (pending)" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       grade_numeric: nil)
      expect(component.grade_display(participation)).to eq("\u2014")
    end

    it "shows combined display when grade_text differs from numeric" do
      participation = build(:assessment_participation, assessment: assessment,
                                                       grade_numeric: 4.0,
                                                       grade_text: "ausreichend")
      expect(component.grade_display(participation)).to eq("4.0 (ausreichend)")
    end
  end

  describe "#excluded_participations" do
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) do
      exam.ensure_gradebook!
      exam.assessment
    end
    let(:component) { described_class.new(assessment: assessment) }

    it "combines absent and exempt into one collection" do
      create(:assessment_participation, :absent,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation, :exempt,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation, :submitted,
             assessment: assessment, tutorial: tutorial)

      expect(component.excluded_participations.count).to eq(2)
    end
  end

  describe "#status_label" do
    let(:assignment) { create(:valid_assignment, lecture: lecture) }
    let(:assessment) { assignment.reload.assessment }
    let(:component) { described_class.new(assessment: assessment) }

    it "returns the absent label" do
      p = build(:assessment_participation, :absent, assessment: assessment)
      expect(component.status_label(p)).to eq(
        I18n.t("assessment.grade_table.absent")
      )
    end

    it "returns the exempt label" do
      p = build(:assessment_participation, :exempt, assessment: assessment)
      expect(component.status_label(p)).to eq(
        I18n.t("assessment.grade_table.exempt")
      )
    end
  end

  describe "excluded students card rendering" do
    let(:exam) { create(:exam, lecture: lecture) }
    let(:assessment) do
      exam.ensure_gradebook!
      exam.assessment
    end
    let(:component) { described_class.new(assessment: assessment) }

    it "renders separate absent and exempt cards" do
      create(:assessment_participation, :absent,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation, :exempt,
             assessment: assessment, tutorial: tutorial)

      render_inline(component)
      expect(rendered_content).to include("bi-person-x")
      expect(rendered_content).to include("bi-person-dash")
    end

    it "shows absent student with grade badge" do
      absent = create(:assessment_participation, :absent,
                      assessment: assessment, tutorial: tutorial)

      render_inline(component)
      expect(rendered_content).to include(absent.user.tutorial_name)
      expect(rendered_content).to include("5.0")
    end

    it "does not render the card when no excluded students" do
      create(:assessment_participation, :submitted,
             assessment: assessment, tutorial: tutorial)

      render_inline(component)
      expect(rendered_content).not_to include("bi-person-x")
      expect(rendered_content).not_to include("bi-person-dash")
    end
  end
end
