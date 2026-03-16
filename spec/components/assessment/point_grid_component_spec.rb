require "rails_helper"

RSpec.describe(PointGridComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:assignment) { create(:valid_assignment, lecture: lecture) }
  let(:assessment) { assignment.reload.assessment }
  let(:component) { described_class.new(assessment: assessment) }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  context "when no tasks exist" do
    it "renders the no-tasks empty state" do
      render_inline(component)
      expect(rendered_content).to include(I18n.t("assessment.no_tasks_yet"))
    end

    it "reports any_scoring? as false" do
      expect(component.any_scoring?).to be(false)
    end
  end

  context "when tasks exist but no points entered" do
    before do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
      create(:assessment_participation, :submitted,
             assessment: assessment, tutorial: tutorial)
    end

    it "renders the table with dashes for ungraded participations" do
      render_inline(component)
      expect(rendered_content).to include("\u2014")
    end

    it "reports any_scoring? as true" do
      expect(component.any_scoring?).to be(true)
    end
  end

  context "when task points have been entered" do
    let!(:task1) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end
    let!(:task2) do
      create(:assessment_task, assessment: assessment,
                               max_points: 20, position: 2,
                               description: "Problem 2")
    end
    let!(:participation) do
      create(:assessment_participation, :reviewed,
             assessment: assessment, tutorial: tutorial,
             points_total: 22.5)
    end
    let!(:tp1) do
      create(:assessment_task_point,
             task: task1,
             assessment_participation: participation,
             points: 8)
    end
    let!(:tp2) do
      create(:assessment_task_point,
             task: task2,
             assessment_participation: participation,
             points: 14.5)
    end

    it "reports any_scoring? as true" do
      expect(component.any_scoring?).to be(true)
    end

    it "renders the student name" do
      render_inline(component)
      expect(rendered_content).to include(participation.user.tutorial_name)
    end

    it "renders task descriptions in the header" do
      render_inline(component)
      expect(rendered_content).to include("Problem 1")
      expect(rendered_content).to include("Problem 2")
    end

    it "renders max points per task" do
      render_inline(component)
      expect(rendered_content).to include("/ 10")
      expect(rendered_content).to include("/ 20")
    end

    it "renders individual task points" do
      render_inline(component)
      expect(rendered_content).to include("8")
      expect(rendered_content).to include("14.5")
    end

    it "renders the total points" do
      render_inline(component)
      expect(rendered_content).to include("22.5")
    end

    it "renders the max total" do
      render_inline(component)
      expect(rendered_content).to include("/ 30")
    end

    it "shows the tutorial column for assignments" do
      expect(component.show_tutorial_column?).to be(true)
    end
  end

  context "with mixed participation statuses" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end

    before do
      create(:assessment_participation, :submitted,
             assessment: assessment, tutorial: tutorial)
      reviewed = create(:assessment_participation, :reviewed,
                        assessment: assessment, tutorial: tutorial,
                        points_total: 7)
      create(:assessment_task_point,
             task: task,
             assessment_participation: reviewed,
             points: 7)
      create(:assessment_participation, :absent,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation,
             assessment: assessment, tutorial: tutorial,
             status: :pending, submitted_at: nil)
    end

    it "includes only submitted pending and reviewed in scoring" do
      expect(component.scoring_participations.count).to eq(2)
    end

    it "separates absent into excluded list" do
      expect(component.absent_participations.count).to eq(1)
    end

    it "separates non-submitters into excluded list" do
      expect(component.not_submitted_participations.count).to eq(1)
    end

    it "renders both grid and summary card" do
      render_inline(component)
      expect(rendered_content).to include("7")
      expect(rendered_content).to include(
        I18n.t("assessment.grade_table.absent")
      )
    end
  end

  context "with an absent participation" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end

    let!(:absent_participation) do
      create(:assessment_participation, :absent,
             assessment: assessment, tutorial: tutorial)
    end

    it "does not include absent in the main grid" do
      expect(component.scoring_participations).to be_empty
    end

    it "lists absent in the summary card" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_table.excluded_heading")
      )
      expect(rendered_content).to include(
        absent_participation.user.tutorial_name
      )
    end
  end

  context "with an exempt participation" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end

    let!(:exempt_participation) do
      create(:assessment_participation, :exempt,
             assessment: assessment, tutorial: tutorial)
    end

    it "does not include exempt in the main grid" do
      expect(component.scoring_participations).to be_empty
    end

    it "shows exempt in the summary card" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_table.exempt")
      )
    end
  end

  describe "#excluded_participations" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end

    before do
      create(:assessment_participation, :absent,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation, :exempt,
             assessment: assessment, tutorial: tutorial)
      create(:assessment_participation,
             assessment: assessment, tutorial: tutorial,
             status: :pending, submitted_at: nil)
    end

    it "combines absent, exempt, and non-submitters" do
      expect(component.excluded_participations.count).to eq(3)
    end
  end

  describe "#status_label" do
    it "returns the i18n label for absent" do
      p = build(:assessment_participation, :absent, assessment: assessment)
      expect(component.status_label(p)).to eq(
        I18n.t("assessment.grade_table.absent")
      )
    end

    it "returns the i18n label for exempt" do
      p = build(:assessment_participation, :exempt, assessment: assessment)
      expect(component.status_label(p)).to eq(
        I18n.t("assessment.grade_table.exempt")
      )
    end

    it "returns the i18n label for not submitted" do
      p = build(:assessment_participation, assessment: assessment,
                                           status: :pending,
                                           submitted_at: nil)
      expect(component.status_label(p)).to eq(
        I18n.t("assessment.grade_table.not_submitted")
      )
    end
  end

  context "with a non-submitted participation" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end

    before do
      create(:assessment_participation,
             assessment: assessment, tutorial: tutorial,
             status: :pending, submitted_at: nil)
    end

    it "does not include non-submitters in the main grid" do
      expect(component.scoring_participations).to be_empty
    end

    it "lists non-submitters in the summary card" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_table.not_submitted")
      )
    end
  end

  describe "#points_display" do
    let!(:task) do
      create(:assessment_task, assessment: assessment,
                               max_points: 10, position: 1,
                               description: "Problem 1")
    end
    let!(:participation) do
      create(:assessment_participation, :reviewed,
             assessment: assessment, tutorial: tutorial,
             points_total: 0)
    end

    it "returns dash when no task point exists" do
      expect(component.points_display(participation, task)).to eq("—")
    end

    it "formats whole numbers without decimals" do
      create(:assessment_task_point,
             task: task,
             assessment_participation: participation,
             points: 8.0)
      expect(component.points_display(participation, task)).to eq("8")
    end

    it "preserves decimal points" do
      create(:assessment_task_point,
             task: task,
             assessment_participation: participation,
             points: 7.5)
      expect(component.points_display(participation, task)).to eq("7.5")
    end
  end

  describe "#total_display" do
    it "returns dash when points_total is nil" do
      participation = build(:assessment_participation,
                            assessment: assessment, points_total: nil)
      expect(component.total_display(participation)).to eq("—")
    end

    it "formats whole totals without decimals" do
      participation = build(:assessment_participation,
                            assessment: assessment, points_total: 30.0)
      expect(component.total_display(participation)).to eq("30")
    end
  end

  context "with an exam (Pointable + Gradable)" do
    let(:exam) { create(:exam, :written, lecture: lecture) }
    let(:exam_assessment) { exam.reload.assessment }
    let(:exam_component) { described_class.new(assessment: exam_assessment) }

    let!(:task) do
      create(:assessment_task, assessment: exam_assessment,
                               max_points: 15, position: 1,
                               description: "Aufgabe 1")
    end
    let!(:participation) do
      create(:assessment_participation, :reviewed,
             assessment: exam_assessment, tutorial: tutorial,
             points_total: 12.5)
    end
    let!(:tp) do
      create(:assessment_task_point,
             task: task,
             assessment_participation: participation,
             points: 12.5)
    end

    it "renders the point grid for an exam" do
      render_inline(exam_component)
      expect(rendered_content).to include("Aufgabe 1")
      expect(rendered_content).to include("12.5")
      expect(rendered_content).to include("/ 15")
    end

    it "shows the tutorial column (exams are not talks)" do
      expect(exam_component.show_tutorial_column?).to be(true)
    end
  end
end
