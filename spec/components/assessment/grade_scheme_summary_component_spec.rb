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
    it "returns bg-success for grade 1.0" do
      expect(component.badge_class("1.0")).to eq("bg-success")
    end

    it "returns bg-danger for grade 5.0" do
      expect(component.badge_class("5.0")).to eq("bg-danger")
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

  describe "#failed?" do
    it "returns true for grade 5.0" do
      band = { "grade" => "5.0", "min_points" => 0 }
      expect(component.failed?(band)).to be(true)
    end

    it "returns false for grade 4.0" do
      band = { "grade" => "4.0", "min_points" => 24 }
      expect(component.failed?(band)).to be(false)
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
