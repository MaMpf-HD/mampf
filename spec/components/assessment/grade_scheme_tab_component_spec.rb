require "rails_helper"

RSpec.describe(GradeSchemeTabComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) { exam.reload.assessment }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  let(:component) { described_class.new(assessment: assessment) }

  describe "#show_form?" do
    context "when no grade_scheme passed" do
      it "returns false" do
        expect(component.show_form?).to be(false)
      end
    end

    context "when grade_scheme is passed" do
      let(:gs) { assessment.build_grade_scheme(kind: :banded) }
      let(:component_with_form) do
        described_class.new(assessment: assessment, grade_scheme: gs)
      end

      it "returns true" do
        expect(component_with_form.show_form?).to be(true)
      end
    end
  end

  describe "#phase" do
    context "when no participations exist" do
      it "returns :no_scheme" do
        expect(component.phase).to eq(:no_scheme)
      end
    end

    context "when some participations are pending, no scheme" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :pending,
               assessment: assessment)
      end

      it "returns :no_scheme" do
        expect(component.phase).to eq(:no_scheme)
      end
    end

    context "when all participations are reviewed, no scheme" do
      before do
        create_list(:assessment_participation, 3, :reviewed,
                    assessment: assessment)
      end

      it "returns :no_scheme" do
        expect(component.phase).to eq(:no_scheme)
      end
    end

    context "when scheme exists but not applied" do
      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
        create(:assessment_grade_scheme, assessment: assessment)
      end

      it "returns :draft" do
        expect(component.phase).to eq(:draft)
      end
    end

    context "when scheme exists with pending students" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :pending,
               assessment: assessment)
        create(:assessment_grade_scheme, assessment: assessment)
      end

      it "returns :draft" do
        expect(component.phase).to eq(:draft)
      end
    end

    context "when scheme is applied" do
      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
        create(:assessment_grade_scheme, :applied,
               assessment: assessment)
      end

      it "returns :applied" do
        expect(component.phase).to eq(:applied)
      end
    end
  end

  describe "#pending_participations?" do
    context "when no pending participations" do
      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
      end

      it "returns false" do
        expect(component.pending_participations?).to be(false)
      end
    end

    context "when pending participations exist" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :pending,
               assessment: assessment)
      end

      it "returns true" do
        expect(component.pending_participations?).to be(true)
      end
    end

    context "when absent and exempt but no pending" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :absent,
               assessment: assessment)
        create(:assessment_participation, :exempt,
               assessment: assessment)
      end

      it "returns false" do
        expect(component.pending_participations?).to be(false)
      end
    end
  end

  describe "rendering" do
    context "pending banner" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :pending,
               assessment: assessment)
      end

      it "shows the pending warning banner" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.pending_title")
        )
      end

      it "shows pending count" do
        render_inline(component)
        expect(rendered_content).to include("1")
        expect(rendered_content).to include("2")
      end
    end

    context "no pending banner when all reviewed" do
      before do
        create_list(:assessment_participation, 3, :reviewed,
                    assessment: assessment)
      end

      it "does not show the pending warning" do
        render_inline(component)
        expect(rendered_content).not_to include(
          I18n.t("assessment.grade_scheme.pending_title")
        )
      end
    end

    context "phase :no_scheme" do
      before do
        create_list(:assessment_participation, 3, :reviewed,
                    assessment: assessment)
      end

      it "renders the create button" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.create_button")
        )
      end
    end

    context "phase :no_scheme with pending students" do
      before do
        create(:assessment_participation, :reviewed,
               assessment: assessment)
        create(:assessment_participation, :pending,
               assessment: assessment)
      end

      it "renders both pending banner and create button" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.pending_title")
        )
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.create_button")
        )
      end
    end

    context "phase :draft" do
      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
        create(:assessment_grade_scheme, assessment: assessment)
      end

      it "renders the draft info alert" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.draft_title")
        )
      end

      it "renders edit, preview, and apply buttons" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.edit_button")
        )
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.preview_button")
        )
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.apply_button")
        )
      end
    end

    context "phase :applied" do
      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
        create(:assessment_grade_scheme, :applied,
               assessment: assessment)
      end

      it "renders the applied success alert" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.applied_title")
        )
      end
    end

    context "when grade_scheme is passed (form mode)" do
      let(:gs) { assessment.build_grade_scheme(kind: :banded) }
      let(:form_component) do
        described_class.new(assessment: assessment, grade_scheme: gs)
      end

      before do
        create_list(:assessment_participation, 2, :reviewed,
                    assessment: assessment)
      end

      it "renders the scheme form instead of phase content" do
        render_inline(form_component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.form.title")
        )
        expect(rendered_content).not_to include(
          I18n.t("assessment.grade_scheme.create_button")
        )
      end
    end
  end
end
