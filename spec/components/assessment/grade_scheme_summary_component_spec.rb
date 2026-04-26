require "rails_helper"

RSpec.describe(GradeSchemeSummaryComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) { exam.reload.assessment }
  let(:grade_scheme) do
    create(:assessment_grade_scheme, assessment: assessment)
  end
  let(:component) do
    described_class.new(assessment: assessment, grade_scheme: grade_scheme)
  end

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  describe "#bands" do
    it "returns bands sorted ascending by grade string value" do
      grades = component.bands.pluck("grade")
      expect(grades.first).to eq("1.0")
      expect(grades.last).to eq("5.0")
    end
  end

  describe "#badge_class" do
    it "returns the success-subtle palette for grade 1.0" do
      expect(component.badge_class("1.0"))
        .to eq("bg-success-subtle text-success-emphasis")
    end

    it "returns the danger-subtle palette for grade 5.0" do
      expect(component.badge_class("5.0"))
        .to eq("bg-danger-subtle text-danger-emphasis")
    end

    it "returns bg-secondary for unknown grade" do
      expect(component.badge_class("9.9")).to eq("bg-secondary")
    end
  end

  describe "#student_counts and #count_for" do
    before do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 25)
    end

    it "assigns 1.0 to a student with 55 points" do
      band_one = component.bands.find { |b| b["grade"] == "1.0" }
      expect(component.count_for(band_one)).to eq(1)
    end

    it "assigns 4.0 to a student with 25 points (between 24 and 27)" do
      band_four = component.bands.find { |b| b["grade"] == "4.0" }
      expect(component.count_for(band_four)).to eq(1)
    end
  end

  describe "#pass_count and #fail_count" do
    before do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 5)
    end

    it "counts one passing student" do
      expect(component.pass_count).to eq(1)
    end

    it "counts one failing student" do
      expect(component.fail_count).to eq(1)
    end
  end

  describe "#pass_rate and #fail_rate" do
    context "with no reviewed students" do
      it "returns 0.0 for pass_rate" do
        expect(component.pass_rate).to eq(0.0)
      end

      it "returns 0.0 for fail_rate" do
        expect(component.fail_rate).to eq(0.0)
      end
    end

    context "with two students, one passing" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 55)
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 5)
      end

      it "returns 50.0 for pass_rate" do
        expect(component.pass_rate).to eq(50.0)
      end

      it "returns 50.0 for fail_rate" do
        expect(component.fail_rate).to eq(50.0)
      end
    end
  end

  describe "#absent_count and #exempt_count" do
    before do
      create(:assessment_participation, :absent, assessment: assessment)
      create(:assessment_participation, :exempt, assessment: assessment)
    end

    it "counts absent students" do
      expect(component.absent_count).to eq(1)
    end

    it "counts exempt students" do
      expect(component.exempt_count).to eq(1)
    end

    it "reports any_excluded? as true" do
      expect(component.any_excluded?).to be(true)
    end
  end

  describe "#any_excluded?" do
    context "without absent or exempt students" do
      it "returns false" do
        expect(component.any_excluded?).to be(false)
      end
    end
  end

  describe "#fail_boundary?" do
    it "is true at the index where 4.0 transitions to 5.0" do
      idx = component.bands.index { |b| b["grade"] == "5.0" }
      expect(component.fail_boundary?(idx)).to be(true)
    end

    it "is false for the first row" do
      expect(component.fail_boundary?(0)).to be(false)
    end

    it "is false at intra-passing transitions (e.g. 1.0 -> 1.3)" do
      idx = component.bands.index { |b| b["grade"] == "1.3" }
      expect(component.fail_boundary?(idx)).to be(false)
    end
  end

  describe "#total_reviewed" do
    it "returns 0 when no participations" do
      expect(component.total_reviewed).to eq(0)
    end

    it "counts only reviewed participations" do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 50)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 10)
      create(:assessment_participation, :pending, assessment: assessment)
      create(:assessment_participation, :absent, assessment: assessment)
      expect(component.total_reviewed).to eq(2)
    end
  end

  describe "#bar_width" do
    before do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 25)
    end

    it "returns 100 for the band with the highest count" do
      band_one = component.bands.find { |b| b["grade"] == "1.0" }
      expect(component.bar_width(band_one)).to eq(100)
    end

    it "returns 50 for a band with half the maximum count" do
      band_four = component.bands.find { |b| b["grade"] == "4.0" }
      expect(component.bar_width(band_four)).to eq(50)
    end

    it "returns 0 for a band with no students" do
      band_two = component.bands.find { |b| b["grade"] == "2.0" }
      expect(component.bar_width(band_two)).to eq(0)
    end

    it "returns 0 when there are no reviewed students" do
      assessment.assessment_participations.destroy_all
      band_one = component.bands.find { |b| b["grade"] == "1.0" }
      expect(component.bar_width(band_one)).to eq(0)
    end
  end

  describe "comparison mode" do
    let(:previous_scheme_config) do
      {
        "bands" => [
          { "min_points" => 50, "grade" => "1.0" },
          { "min_points" => 45, "grade" => "1.3" },
          { "min_points" => 40, "grade" => "1.7" },
          { "min_points" => 35, "grade" => "2.0" },
          { "min_points" => 30, "grade" => "2.3" },
          { "min_points" => 25, "grade" => "3.0" },
          { "min_points" => 20, "grade" => "3.7" },
          { "min_points" => 15, "grade" => "4.0" },
          { "min_points" => 0,  "grade" => "5.0" }
        ]
      }
    end
    let!(:previous_applied) do
      create(:assessment_grade_scheme, :applied,
             assessment: assessment, active: false,
             config: previous_scheme_config)
    end
    let(:draft_scheme) do
      create(:assessment_grade_scheme, :draft,
             assessment: assessment)
    end
    let(:draft_component) do
      described_class.new(assessment: assessment, grade_scheme: draft_scheme)
    end

    before do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 22)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 18)
    end

    describe "#previous_applied_scheme" do
      it "returns the most recently applied prior scheme" do
        expect(draft_component.previous_applied_scheme)
          .to eq(previous_applied)
      end

      it "is nil for a freshly applied scheme with no prior" do
        previous_applied.destroy
        applied = create(:assessment_grade_scheme, :applied,
                         assessment: assessment, active: true)
        comp = described_class.new(assessment: assessment,
                                   grade_scheme: applied)
        expect(comp.previous_applied_scheme).to be_nil
      end
    end

    describe "#comparing?" do
      it "is true for a draft when a previous applied scheme exists" do
        expect(draft_component.comparing?).to be(true)
      end

      it "is false for the currently applied scheme even with prior" do
        applied = create(:assessment_grade_scheme, :applied,
                         assessment: assessment, active: true)
        comp = described_class.new(assessment: assessment,
                                   grade_scheme: applied)
        expect(comp.comparing?).to be(false)
      end

      it "is false for a draft when no previous applied scheme exists" do
        previous_applied.destroy
        expect(draft_component.comparing?).to be(false)
      end
    end

    describe "#applied_bands" do
      it "returns the previous applied scheme's bands sorted ascending" do
        grades = draft_component.applied_bands.pluck("grade")
        expect(grades.first).to eq("1.0")
        expect(grades.last).to eq("5.0")
      end
    end

    describe "#applied_counts" do
      it "applies the previous bands to current points" do
        counts = draft_component.applied_counts
        expect(counts["1.0"]).to eq(1)
        expect(counts["3.7"]).to eq(1)
        expect(counts["4.0"]).to eq(1)
        expect(counts["5.0"]).to eq(0)
      end
    end

    describe "#applied_pass_count and #applied_fail_count" do
      it "splits the applied bands at the 4.0 boundary" do
        expect(draft_component.applied_pass_count).to eq(3)
        expect(draft_component.applied_fail_count).to eq(0)
      end
    end

    describe "#applied_pass_rate and #applied_fail_rate" do
      it "returns the rounded percentage of passing students" do
        expect(draft_component.applied_pass_rate).to eq(100.0)
        expect(draft_component.applied_fail_rate).to eq(0.0)
      end

      it "returns 0.0 when there are no reviewed students" do
        assessment.assessment_participations.destroy_all
        expect(draft_component.applied_pass_rate).to eq(0.0)
        expect(draft_component.applied_fail_rate).to eq(0.0)
      end
    end

    describe "#grade_change_summary" do
      it "counts students with worse, better, and unchanged grades" do
        summary = draft_component.grade_change_summary
        expect(summary[:better]).to eq(0)
        expect(summary[:worse]).to eq(2)
        expect(summary[:unchanged]).to eq(1)
      end

      it "tracks newly_failing transitions across the 4.0 boundary" do
        summary = draft_component.grade_change_summary
        expect(summary[:newly_failing]).to eq(2)
        expect(summary[:newly_passing]).to eq(0)
      end

      it "returns zeros when there are no reviewed students" do
        assessment.assessment_participations.destroy_all
        summary = draft_component.grade_change_summary
        expect(summary).to eq(better: 0, worse: 0, unchanged: 0,
                              newly_failing: 0, newly_passing: 0)
      end
    end

    describe "rendering" do
      it "renders the side-by-side comparison alert" do
        render_inline(draft_component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.summary.changes_intro")
        )
      end

      it "renders mirrored saved/proposed bar headings" do
        render_inline(draft_component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.summary.saved_bar")
        )
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.summary.proposed_bar")
        )
      end
    end
  end

  describe "#pct_scheme?" do
    it "returns false for a min_points scheme" do
      expect(component.pct_scheme?).to be(false)
    end

    context "with a min_pct scheme" do
      let(:pct_scheme) do
        create(:assessment_grade_scheme, :percentage,
               assessment: assessment, active: false)
      end
      let(:pct_comp) do
        described_class.new(assessment: assessment, grade_scheme: pct_scheme)
      end

      it "returns true" do
        expect(pct_comp.pct_scheme?).to be(true)
      end

      it "student_counts returns empty hash without crashing" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 50)
        expect(pct_comp.student_counts).to eq({})
      end

      it "renders the unsupported format warning" do
        render_inline(pct_comp)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.unsupported_pct_format")
        )
      end

      it "does not render the grade bands table" do
        render_inline(pct_comp)
        expect(rendered_content).not_to include(
          I18n.t("assessment.grade_scheme.summary.title")
        )
      end
    end
  end
end
