require "rails_helper"

RSpec.describe(SchemeFormComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: teacher) }
  let(:exam) { create(:exam, lecture: lecture) }
  let(:assessment) { exam.reload.assessment }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  describe "new scheme (not persisted)" do
    let(:grade_scheme) do
      assessment.build_grade_scheme(kind: :banded)
    end
    let(:component) do
      described_class.new(assessment: assessment, grade_scheme: grade_scheme)
    end

    it "renders the form title" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.title")
      )
    end

    it "renders two-point auto and manual curve tabs" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.two_point_auto")
      )
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.manual_curve")
      )
    end

    it "renders excellence and passing inputs" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.excellence_label")
      )
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.passing_label")
      )
    end

    it "renders the generate button" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.generate_button")
      )
    end

    it "renders the save draft button" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.save_draft")
      )
    end

    it "renders the cancel link" do
      render_inline(component)
      expect(rendered_content).to include(
        I18n.t("assessment.grade_scheme.form.cancel")
      )
    end

    it "has the stimulus controller attribute" do
      render_inline(component)
      expect(rendered_content).to include(
        'data-controller="assessments--scheme-form"'
      )
    end

    it "sets the hidden config field target" do
      render_inline(component)
      expect(rendered_content).to include("configField")
    end
  end

  describe "#form_url" do
    context "when new (not persisted)" do
      let(:grade_scheme) do
        assessment.build_grade_scheme(kind: :banded)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "renders a form posting to the create path" do
        render_inline(component)
        path = Rails.application.routes.url_helpers
                    .assessment_assessment_grade_schemes_path(assessment)
        expect(rendered_content).to include(path)
      end
    end

    context "when editing (persisted)" do
      let!(:grade_scheme) do
        create(:assessment_grade_scheme, assessment: assessment)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "renders a form posting to the update path" do
        render_inline(component)
        path = Rails.application.routes.url_helpers
                    .assessment_assessment_grade_scheme_path(
                      assessment, grade_scheme
                    )
        expect(rendered_content).to include(path)
      end
    end
  end

  describe "#form_method" do
    context "when new" do
      let(:grade_scheme) do
        assessment.build_grade_scheme(kind: :banded)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "returns :post" do
        expect(component.form_method).to eq(:post)
      end
    end

    context "when editing" do
      let!(:grade_scheme) do
        create(:assessment_grade_scheme, assessment: assessment)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "returns :patch" do
        expect(component.form_method).to eq(:patch)
      end
    end
  end

  describe "#max_points" do
    let(:grade_scheme) do
      assessment.build_grade_scheme(kind: :banded)
    end
    let(:component) do
      described_class.new(assessment: assessment, grade_scheme: grade_scheme)
    end

    it "returns the effective total points" do
      expect(component.max_points).to eq(
        assessment.effective_total_points || 0
      )
    end
  end

  describe "#default_excellence and #default_passing" do
    context "when no existing bands" do
      let(:grade_scheme) do
        assessment.build_grade_scheme(kind: :banded)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "computes defaults from max_points" do
        max = component.max_points
        expect(component.default_excellence).to eq((max * 0.9).round)
        expect(component.default_passing).to eq((max * 0.5).round)
      end
    end

    context "when editing with existing bands" do
      let!(:grade_scheme) do
        config = Assessment::GradeScheme.two_point_auto(
          excellence: 54, passing: 30, max_points: 60
        )
        create(:assessment_grade_scheme,
               assessment: assessment, config: config)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "extracts excellence from 1.0 band" do
        expect(component.default_excellence).to eq(54)
      end

      it "extracts passing from 4.0 band" do
        expect(component.default_passing).to eq(30)
      end
    end
  end

  describe "#editing?" do
    context "when new" do
      let(:grade_scheme) do
        assessment.build_grade_scheme(kind: :banded)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "returns false" do
        expect(component.editing?).to be(false)
      end
    end

    context "when persisted" do
      let!(:grade_scheme) do
        create(:assessment_grade_scheme, assessment: assessment)
      end
      let(:component) do
        described_class.new(
          assessment: assessment,
          grade_scheme: grade_scheme
        )
      end

      it "returns true" do
        expect(component.editing?).to be(true)
      end
    end
  end
end
