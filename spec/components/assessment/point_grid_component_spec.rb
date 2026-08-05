require "rails_helper"

RSpec.describe(PointGridComponent, type: :component) do
  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  # Expired, because nothing may be marked while the deadline is still running.
  let(:assignment) { create(:assignment, :with_lecture, :expired) }
  let(:assessment) { assignment.reload.assessment }

  def add_task(max_points: 10, description: "Sums")
    create(:assessment_task, assessment: assessment,
                             max_points: max_points, description: description)
  end

  def add_participation(**attrs)
    create(:assessment_participation, assessment: assessment, **attrs)
  end

  def render_grid
    render_inline(described_class.new(assessment: assessment))
  end

  def texts(selector)
    render_grid.css(selector).map { |node| node.text.strip.gsub(/\s+/, " ") }
  end

  it "asks for tasks before it asks for points" do
    render_grid
    expect(rendered_content).to include(I18n.t("assessment.no_tasks_yet"))
    expect(rendered_content).not_to include(I18n.t("assessment.no_points_yet"))
  end

  it "reports that nobody has been scored yet once tasks exist" do
    add_task
    render_grid
    expect(rendered_content).to include(I18n.t("assessment.no_points_yet"))
  end

  context "with a scored participant" do
    let(:task) { add_task }
    let(:participant) { add_participation(status: :reviewed, submitted_at: 1.day.ago) }

    before do
      create(:assessment_task_point, task: task,
                                     assessment_participation: participant, points: 7.5)
    end

    it "shows the points of the task and the total" do
      expect(texts("tbody td").last(2)).to eq(["7.5", "7.5"])
    end

    it "writes a whole maximum without a decimal tail" do
      expect(texts("thead th")).to include("Sums / 10")
    end
  end

  it "numbers a task that carries no name" do
    add_task(description: nil)
    add_participation(status: :reviewed, submitted_at: 1.day.ago)
    default_name = I18n.t("assessment.task.default_name", number: 1)
    expect(texts("thead th")).to include("#{default_name} / 10")
  end

  it "leaves a dash where a task has not been scored" do
    add_task
    add_task(description: "Proofs")
    participant = add_participation(status: :reviewed, submitted_at: 1.day.ago)
    create(:assessment_task_point, task: assessment.tasks.order(:position).first,
                                   assessment_participation: participant, points: 4)
    expect(texts("tbody td")).to include("—")
  end

  describe "the special cases" do
    before do
      add_task
      add_participation(status: :pending, submitted_at: nil)
      add_participation(status: :absent)
      add_participation(status: :exempt)
    end

    it "collects everyone who is out of the scoring" do
      expect(texts(".badge")).to include("3")
      expect(rendered_content).to include(I18n.t("assessment.grade_table.excluded_heading"))
    end

    it "names the reason for each of them" do
      reasons = texts("tbody td")
      expect(reasons).to include(I18n.t("assessment.grade_table.not_submitted"))
      expect(reasons).to include(I18n.t("assessment.grade_table.absent"))
      expect(reasons).to include(I18n.t("assessment.grade_table.exempt"))
    end
  end
end
