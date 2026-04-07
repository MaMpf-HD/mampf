require "rails_helper"

RSpec.describe(GradingOverviewComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:assignment) { create(:valid_assignment, lecture: lecture) }
  let(:assessment) { assignment.reload.assessment }
  let(:component) { described_class.new(assessment: assessment, lecture: lecture) }

  let!(:tutorial1) { create(:tutorial, lecture: lecture, title: "Tutorial A") }
  let!(:tutorial2) { create(:tutorial, lecture: lecture, title: "Tutorial B") }

  let(:user1) { create(:confirmed_user) }
  let(:user2) { create(:confirmed_user) }
  let(:user3) { create(:confirmed_user) }

  before do
    Flipper.enable(:assessment_grading)
    create(:tutorial_membership, tutorial: tutorial1, user: user1)
    create(:tutorial_membership, tutorial: tutorial1, user: user2)
    create(:tutorial_membership, tutorial: tutorial2, user: user3)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  describe "#requires_submission?" do
    it "returns true when assessment requires submission" do
      assessment.update!(requires_submission: true)
      expect(component.requires_submission?).to be(true)
    end

    it "returns false when assessment does not require submission" do
      assessment.update!(requires_submission: false)
      expect(component.requires_submission?).to be(false)
    end
  end

  describe "rendering" do
    context "when requires_submission is false" do
      before { assessment.update!(requires_submission: false) }

      it "shows no submission required message" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grading_overview.no_submission_required")
        )
      end

      it "shows expected participant count from roster" do
        render_inline(component)
        expect(rendered_content).to include("3")
        expect(rendered_content).to include(I18n.t("assessment.participants"))
      end
    end

    context "when requires_submission is true" do
      before { assessment.update!(requires_submission: true) }

      it "shows submission progress" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grading_overview.submission_progress")
        )
      end

      it "shows tutorial breakdown when roster has members" do
        render_inline(component)
        expect(rendered_content).to include("Tutorial A")
        expect(rendered_content).to include("Tutorial B")
      end
    end
  end

  describe "#total_expected" do
    it "returns count of all roster members" do
      expect(component.total_expected).to eq(3)
    end

    it "returns 0 when roster is empty" do
      TutorialMembership.delete_all
      expect(component.total_expected).to eq(0)
    end
  end

  describe "#submitted_count" do
    it "counts participations with submitted_at present" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user2, tutorial: tutorial1,
                                        submitted_at: 2.days.ago)

      expect(component.submitted_count).to eq(2)
    end

    it "returns 0 when no participations exist (lazy creation)" do
      expect(component.submitted_count).to eq(0)
    end

    it "excludes participations without submitted_at" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user2, tutorial: tutorial1,
                                        submitted_at: nil)

      expect(component.submitted_count).to eq(1)
    end

    it "excludes exempt participations (submitted_at is nil)" do
      create(:assessment_participation, assessment: assessment,
                                        user: user2, tutorial: tutorial1,
                                        status: :exempt, submitted_at: nil)

      expect(component.submitted_count).to eq(0)
    end
  end

  describe "#missing_count" do
    it "returns difference between expected roster count and submitted" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)

      expect(component.missing_count).to eq(2)
    end

    it "equals total_expected when no submissions" do
      expect(component.missing_count).to eq(3)
    end
  end

  describe "#progress_percentage" do
    it "returns 0 when no roster members" do
      TutorialMembership.delete_all
      expect(component.progress_percentage).to eq(0)
    end

    it "returns 0 when no submissions yet" do
      expect(component.progress_percentage).to eq(0)
    end

    it "calculates percentage correctly" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)

      expect(component.progress_percentage).to eq(33)
    end

    it "returns 100 when all submitted" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user2, tutorial: tutorial1,
                                        submitted_at: 2.days.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user3, tutorial: tutorial2,
                                        submitted_at: 1.day.ago)

      expect(component.progress_percentage).to eq(100)
    end
  end

  describe "#tutorial_stats" do
    it "groups expected count by tutorial from roster" do
      stats = component.tutorial_stats
      expect(stats.size).to eq(2)

      stat1 = stats.find { |s| s.name == "Tutorial A" }
      expect(stat1.total).to eq(2)
      expect(stat1.submitted).to eq(0)
      expect(stat1.missing).to eq(2)

      stat2 = stats.find { |s| s.name == "Tutorial B" }
      expect(stat2.total).to eq(1)
      expect(stat2.submitted).to eq(0)
      expect(stat2.missing).to eq(1)
    end

    it "counts submissions per tutorial" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)

      stats = component.tutorial_stats
      stat1 = stats.find { |s| s.name == "Tutorial A" }

      expect(stat1.total).to eq(2)
      expect(stat1.submitted).to eq(1)
      expect(stat1.missing).to eq(1)
    end

    it "excludes tutorials with no roster members" do
      create(:tutorial, lecture: lecture, title: "Empty Tutorial")

      stats = component.tutorial_stats
      expect(stats.map(&:name)).not_to include("Empty Tutorial")
    end
  end

  describe "TutorialStat" do
    let(:tutorial) { tutorial1 }
    let(:stat) do
      described_class::TutorialStat.new(tutorial: tutorial, total: 10, submitted: 3)
    end

    it "calculates missing" do
      expect(stat.missing).to eq(7)
    end

    it "calculates progress_percentage" do
      expect(stat.progress_percentage).to eq(30)
    end

    it "returns tutorial title as name" do
      expect(stat.name).to eq("Tutorial A")
    end

    it "returns unassigned label when tutorial is nil" do
      nil_stat = described_class::TutorialStat.new(tutorial: nil, total: 5, submitted: 2)
      expect(nil_stat.name).to eq(I18n.t("assessment.grading_overview.unassigned"))
    end
  end

  describe "#deadline" do
    it "returns the assessable deadline" do
      assignment.update!(deadline: 3.days.from_now)
      expect(component.deadline).to eq(assignment.deadline)
    end
  end

  describe "#deadline_status" do
    context "when deadline is more than 24 hours away" do
      before { assignment.update!(deadline: 3.days.from_now) }

      it "returns open phase" do
        expect(component.deadline_status[:phase]).to eq(:open)
        expect(component.deadline_status[:color]).to eq("text-muted")
      end
    end

    context "when deadline is less than 24 hours away" do
      before { assignment.update!(deadline: 6.hours.from_now) }

      it "returns urgent phase" do
        expect(component.deadline_status[:phase]).to eq(:urgent)
        expect(component.deadline_status[:color]).to eq("text-warning")
      end
    end

    context "when deadline passed less than 24 hours ago" do
      # rubocop:disable Rails/SkipsModelValidations
      before { assignment.update_column(:deadline, 6.hours.ago) }
      # rubocop:enable Rails/SkipsModelValidations

      it "returns just_closed phase" do
        expect(component.deadline_status[:phase]).to eq(:just_closed)
        expect(component.deadline_status[:color]).to eq("text-muted")
      end
    end

    context "when deadline passed more than 24 hours ago" do
      # rubocop:disable Rails/SkipsModelValidations
      before { assignment.update_column(:deadline, 3.days.ago) }
      # rubocop:enable Rails/SkipsModelValidations

      it "returns grading phase" do
        expect(component.deadline_status[:phase]).to eq(:grading)
        expect(component.deadline_status[:color]).to eq("text-success")
      end
    end
  end

  describe "#progress_bar_color" do
    it "returns :success when 100% progress" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user2, tutorial: tutorial1,
                                        submitted_at: 2.days.ago)
      create(:assessment_participation, assessment: assessment,
                                        user: user3, tutorial: tutorial2,
                                        submitted_at: 1.day.ago)
      expect(component.progress_bar_color).to eq(:success)
    end

    it "returns :secondary when less than 100% progress" do
      create(:assessment_participation, assessment: assessment,
                                        user: user1, tutorial: tutorial1,
                                        submitted_at: 1.day.ago)
      expect(component.progress_bar_color).to eq(:secondary)
    end
  end
end
