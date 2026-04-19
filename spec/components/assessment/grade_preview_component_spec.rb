require "rails_helper"

RSpec.describe(GradePreviewComponent, type: :component) do
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

  describe "#preview_rows" do
    context "with no reviewed participations" do
      it "returns an empty array" do
        expect(component.preview_rows).to eq([])
      end
    end

    context "with reviewed participations" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 55)
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 20)
      end

      it "returns one row per reviewed participation" do
        expect(component.preview_rows.size).to eq(2)
      end

      it "includes points and proposed_grade in each row" do
        row = component.preview_rows.find { |r| r[:points] == 55 }
        expect(row).to be_present
        expect(row[:proposed_grade]).to eq(1.0)
      end

      it "proposes 5.0 for points below the lowest passing band" do
        row = component.preview_rows.find { |r| r[:points] == 20 }
        expect(row[:proposed_grade]).to eq(5.0)
      end
    end
  end

  describe "#absent_rows" do
    context "with absent participations" do
      before do
        create(:assessment_participation, :absent, assessment: assessment)
      end

      it "includes the absent participation" do
        expect(component.absent_rows.size).to eq(1)
      end
    end

    context "without absent participations" do
      it "returns empty" do
        expect(component.absent_rows).to eq([])
      end
    end
  end

  describe "#pass_count and #fail_count" do
    before do
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 55)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 5)
      create(:assessment_participation, :reviewed,
             assessment: assessment, points_total: 3)
    end

    it "counts passing students correctly" do
      expect(component.pass_count).to eq(1)
    end

    it "counts failing students correctly" do
      expect(component.fail_count).to eq(2)
    end
  end

  describe "#pass_rate" do
    context "when no reviewed participations" do
      it "returns 0.0" do
        expect(component.pass_rate).to eq(0.0)
      end
    end

    context "with mixed results" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 55)
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 5)
      end

      it "returns the correct percentage" do
        expect(component.pass_rate).to eq(50.0)
      end
    end
  end

  describe "#grade_changed?" do
    it "returns false when no current grade" do
      row = { current_grade: nil, proposed_grade: 2.0 }
      expect(component.grade_changed?(row)).to be(false)
    end

    it "returns false when current and proposed are the same" do
      row = { current_grade: 2.0, proposed_grade: 2.0 }
      expect(component.grade_changed?(row)).to be(false)
    end

    it "returns true when grades differ" do
      row = { current_grade: 3.0, proposed_grade: 2.0 }
      expect(component.grade_changed?(row)).to be(true)
    end
  end

  describe "#total_reviewed" do
    before do
      create_list(:assessment_participation, 3, :reviewed,
                  assessment: assessment)
    end

    it "matches the number of preview rows" do
      expect(component.total_reviewed).to eq(3)
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

      it "preview_rows returns empty without crashing" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, points_total: 50)
        expect(pct_comp.preview_rows).to eq([])
      end

      it "renders the unsupported format warning" do
        render_inline(pct_comp)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.unsupported_pct_format")
        )
      end

      it "does not render the grade preview table" do
        render_inline(pct_comp)
        expect(rendered_content).not_to include(
          I18n.t("assessment.grade_scheme.preview.title")
        )
      end
    end
  end
end
