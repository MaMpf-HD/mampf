require "rails_helper"

RSpec.describe(GradeTableComponent, type: :component) do
  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  let(:talk) { create(:talk) }
  let(:assessment) { talk.reload.assessment }

  def participation(**attrs)
    create(:assessment_participation, assessment: assessment, **attrs)
  end

  def cells(for_assessment = assessment)
    render_inline(described_class.new(assessment: for_assessment))
      .css("tbody td").map { |td| td.text.strip }
  end

  it "asks for the first grade when none has been recorded" do
    render_inline(described_class.new(assessment: assessment))
    expect(rendered_content).to include(I18n.t("assessment.no_grades_yet"))
  end

  it "shows a recorded grade the way it was entered" do
    participation(status: :reviewed, grade_numeric: 2.3, graded_at: 1.hour.ago)
    expect(cells).to include("2.3")
  end

  it "shows both parts when a grade carries a numeric and a textual value" do
    participation(status: :reviewed, grade_numeric: 4.0, grade_text: "borderline",
                  graded_at: 1.hour.ago)
    expect(cells).to include("4.0 (borderline)")
  end

  it "shows a grade that is a word rather than a number" do
    participation(status: :reviewed, grade_text: "pass", graded_at: 1.hour.ago)
    expect(cells).to include("pass")
  end

  context "with an absent participant" do
    it "falls back to the failing grade when none was recorded" do
      participation(status: :absent)
      expect(cells).to include("5.0")
    end

    it "keeps a grade that was recorded anyway" do
      participation(status: :absent, grade_numeric: 4.0)
      expect(cells).to include("4.0")
    end
  end

  it "records no grade for an exempt participant" do
    participation(status: :exempt)
    render_inline(described_class.new(assessment: assessment))
    expect(rendered_content).to include("table-light")
    expect(rendered_content).to include("&mdash;")
  end

  describe "the grader column" do
    let(:first_grader) { create(:confirmed_user) }

    it "stays hidden while a single person graded everything" do
      participation(status: :reviewed, grade_numeric: 1.0, grader: first_grader,
                    graded_at: 1.hour.ago)
      participation(status: :reviewed, grade_numeric: 2.0, grader: first_grader,
                    graded_at: 1.hour.ago)
      render_inline(described_class.new(assessment: assessment))
      expect(rendered_content).not_to include(I18n.t("assessment.graded_by"))
    end

    it "appears as soon as a second person graded" do
      second_grader = create(:confirmed_user)
      participation(status: :reviewed, grade_numeric: 1.0, grader: first_grader,
                    graded_at: 1.hour.ago)
      participation(status: :reviewed, grade_numeric: 2.0, grader: second_grader,
                    graded_at: 1.hour.ago)
      render_inline(described_class.new(assessment: assessment))
      expect(rendered_content).to include(I18n.t("assessment.graded_by"))
      expect(rendered_content).to include(first_grader.tutorial_name)
      expect(rendered_content).to include(second_grader.tutorial_name)
    end
  end

  it "leaves out the tutorial column for a talk" do
    participation(status: :reviewed, grade_numeric: 1.0, graded_at: 1.hour.ago)
    render_inline(described_class.new(assessment: assessment))
    expect(rendered_content).not_to include(I18n.t("basics.tutorial"))
  end
end
