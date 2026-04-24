require "rails_helper"

RSpec.describe(GradingTabComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) do
    exam.ensure_gradebook!
    exam.assessment
  end

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  describe "rendering" do
    context "outside preview mode" do
      let(:component) { described_class.new(assessment: assessment) }

      it "renders the scheme section" do
        render_inline(component)
        expect(rendered_content).to include("data-cy=\"grade-scheme-tab\"")
      end

      it "renders the roster heading and table" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_table.roster_heading")
        )
      end

      it "exposes show_roster? as true" do
        expect(component.show_roster?).to be(true)
      end
    end

    context "in preview mode with a persisted scheme" do
      let!(:grade_scheme) do
        create(:assessment_grade_scheme, assessment: assessment)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme,
          preview_mode: true
        )
      end

      it "suppresses the roster section" do
        expect(component.show_roster?).to be(false)
      end

      it "does not render the roster heading" do
        render_inline(component)
        expect(rendered_content).not_to include(
          I18n.t("assessment.grade_table.roster_heading")
        )
      end
    end

    context "in preview mode without a persisted scheme" do
      let(:component) do
        described_class.new(assessment: assessment, preview_mode: true)
      end

      it "still renders the roster (preview flag is inert)" do
        expect(component.show_roster?).to be(true)
      end
    end
  end
end
