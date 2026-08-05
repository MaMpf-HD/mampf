require "rails_helper"

RSpec.describe(GradingOverviewComponent, type: :component) do
  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:valid_assignment, lecture: lecture) }
  let(:assessment) { assignment.reload.assessment }

  def render_overview
    render_inline(described_class.new(assessment: assessment, lecture: lecture))
  end

  def enrol(count, tutorial: nil)
    tutorial ||= create(:tutorial, lecture: lecture)
    count.times { create(:tutorial_membership, tutorial: tutorial) }
    tutorial
  end

  def submit(count)
    count.times do
      create(:assessment_participation, assessment: assessment,
                                        submitted_at: 1.hour.ago)
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  def deadline_at(time)
    assignment.update_column(:deadline, time)
    assignment.reload
  end
  # rubocop:enable Rails/SkipsModelValidations

  describe "without a required submission" do
    before { assessment.update!(requires_submission: false) }

    it "counts heads instead of tracking progress" do
      enrol(3)
      render_overview
      expect(rendered_content)
        .to include(I18n.t("assessment.grading_overview.no_submission_required"))
      expect(rendered_content).to include("3")
      expect(rendered_content)
        .not_to include(I18n.t("assessment.grading_overview.submission_progress"))
    end
  end

  describe "the deadline notice" do
    it "counts down while the deadline is comfortably away" do
      deadline_at(3.days.from_now)
      render_overview
      expect(rendered_content).to include("bi-hourglass-split")
    end

    it "warns once the deadline is within a day" do
      deadline_at(2.hours.from_now)
      render_overview
      expect(rendered_content).to include("bi-exclamation-triangle")
    end

    it "reports a deadline that has just passed" do
      deadline_at(2.hours.ago)
      render_overview
      expect(rendered_content).to include("bi-inbox")
    end

    it "moves on to the grading phase a day later" do
      deadline_at(3.days.ago)
      render_overview
      expect(rendered_content).to include("bi-check-circle")
    end
  end

  describe "the progress" do
    it "relates submissions to the people on the roster" do
      enrol(4)
      submit(1)
      render_overview
      expect(rendered_content).to include("1/4")
      expect(rendered_content).to include("(25%)")
    end

    it "warns instead of dividing by an empty roster" do
      submit(0)
      render_overview
      expect(rendered_content)
        .to include(I18n.t("assessment.grading_overview.no_participants_yet"))
    end
  end

  describe "the breakdown per tutorial" do
    it "lists a row for every tutorial that has members" do
      monday = create(:tutorial, lecture: lecture, title: "Monday")
      friday = create(:tutorial, lecture: lecture, title: "Friday")
      enrol(2, tutorial: monday)
      enrol(1, tutorial: friday)
      render_overview
      expect(rendered_content).to include("Monday")
      expect(rendered_content).to include("Friday")
    end

    it "leaves out a tutorial nobody joined" do
      enrol(2, tutorial: create(:tutorial, lecture: lecture, title: "Monday"))
      create(:tutorial, lecture: lecture, title: "Empty Slot")
      render_overview
      expect(rendered_content).to include("Monday")
      expect(rendered_content).not_to include("Empty Slot")
    end
  end

  describe "the colour of the progress bar" do
    it "stays neutral while submissions are missing" do
      expect(described_class.progress_bar_color(1, 4)).to eq(:secondary)
    end

    it "turns green once everyone has submitted" do
      expect(described_class.progress_bar_color(4, 4)).to eq(:success)
    end

    it "stays neutral when nobody is expected at all" do
      expect(described_class.progress_bar_color(0, 0)).to eq(:secondary)
      expect(described_class.progress_percentage(0, 0)).to eq(0)
    end
  end
end
