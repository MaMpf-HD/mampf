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

  describe "status counts" do
    before do
      create_list(:assessment_participation, 2, :reviewed,
                  assessment: assessment)
      create_list(:assessment_participation, 3, :pending,
                  assessment: assessment)
      create(:assessment_participation, :absent, assessment: assessment)
      create(:assessment_participation, :exempt, assessment: assessment)
    end

    it "exposes a count per status backed by a single grouped query" do
      expect(component.reviewed_count).to eq(2)
      expect(component.pending_count).to eq(3)
      expect(component.absent_count).to eq(1)
      expect(component.exempt_count).to eq(1)
      expect(component.total_count).to eq(7)
    end

    it "returns 0 for statuses with no participations" do
      assessment.assessment_participations
                .where(status: :reviewed).destroy_all
      fresh = described_class.new(assessment: assessment)
      expect(fresh.reviewed_count).to eq(0)
    end

    it "uses a single grouped query for status_counts" do
      fresh = described_class.new(assessment: assessment)
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        fresh.reviewed_count
        fresh.pending_count
        fresh.absent_count
        fresh.exempt_count
        fresh.total_count
      end
      group_queries = queries.grep(/group by .*status/i)
      expect(group_queries.size).to eq(1)
    end
  end

  describe "#graded_count" do
    it "counts participations with a non-nil grade_numeric" do
      create(:assessment_participation, :reviewed,
             assessment: assessment, grade_numeric: 1.0)
      create(:assessment_participation, :reviewed,
             assessment: assessment, grade_numeric: 5.0)
      create(:assessment_participation, :reviewed,
             assessment: assessment, grade_numeric: nil)
      expect(component.graded_count).to eq(2)
    end

    it "memoizes the count" do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        component.graded_count
        component.graded_count
      end
      expect(queries.grep(/grade_numeric/i).size).to eq(1)
    end
  end

  describe "#ungraded_reviewed_count" do
    context "without an applied scheme" do
      it "returns 0" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, grade_numeric: nil)
        expect(component.ungraded_reviewed_count).to eq(0)
      end
    end

    context "with an applied scheme" do
      before do
        create(:assessment_grade_scheme, :applied, assessment: assessment)
      end

      it "counts reviewed participations missing a grade" do
        create(:assessment_participation, :reviewed,
               assessment: assessment, grade_numeric: nil)
        create(:assessment_participation, :reviewed,
               assessment: assessment, grade_numeric: 1.0)
        expect(component.ungraded_reviewed_count).to eq(1)
      end
    end
  end

  describe "#draft_change_count" do
    it "is 0 when no scheme exists" do
      expect(component.draft_change_count).to eq(0)
    end

    it "is 0 when the scheme is already applied" do
      create(:assessment_grade_scheme, :applied, assessment: assessment)
      expect(component.draft_change_count).to eq(0)
    end

    it "delegates to GradeSchemeApplier when a draft exists" do
      create(:assessment_grade_scheme, assessment: assessment)
      applier = instance_double(Assessment::GradeSchemeApplier,
                                change_count: 7)
      allow(Assessment::GradeSchemeApplier)
        .to receive(:new).and_return(applier)
      expect(component.draft_change_count).to eq(7)
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

      it "renders edit and apply buttons" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.grade_scheme.edit_button")
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
