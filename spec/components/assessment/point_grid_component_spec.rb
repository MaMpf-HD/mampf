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

    it "reports any_participations? as false" do
      expect(component.any_participations?).to be(false)
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

    it "reports any_participations? as true" do
      expect(component.any_participations?).to be(true)
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

    it "reports any_participations? as true" do
      expect(component.any_participations?).to be(true)
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
    end

    it "shows all participations including ungraded" do
      render_inline(component)
      rows = Nokogiri::HTML(rendered_content).css("tbody tr")
      expect(rows.count).to eq(2)
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
end
