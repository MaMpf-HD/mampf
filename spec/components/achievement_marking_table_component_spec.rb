require "rails_helper"

RSpec.describe(AchievementMarkingTableComponent, type: :component) do
  let(:lecture) { create(:lecture, :released_for_all) }

  before { Flipper.enable(:assessment_grading) }
  after { Flipper.disable(:assessment_grading) }

  context "with a boolean achievement" do
    let(:achievement) { create(:achievement, :boolean, lecture: lecture) }
    let(:assessment) do
      achievement.ensure_assessment!(
        requires_points: false, requires_submission: false
      )
    end
    let(:component) { described_class.new(achievement: achievement) }

    context "when no participations exist" do
      it "renders the empty state" do
        render_inline(component)
        expect(rendered_content).to include(
          I18n.t("assessment.achievements.marking.no_participations")
        )
      end

      it "reports any_participations? as false" do
        expect(component.any_participations?).to be(false)
      end
    end

    context "with participations" do
      let!(:passed) do
        create(:assessment_participation,
               assessment: assessment,
               grade_text: "pass")
      end
      let!(:failed) do
        create(:assessment_participation,
               assessment: assessment,
               grade_text: "fail")
      end
      let!(:unmarked) do
        create(:assessment_participation,
               assessment: assessment,
               grade_text: nil)
      end

      it "renders a table with all participations" do
        render_inline(component)
        expect(rendered_content).to include(passed.user.tutorial_name)
        expect(rendered_content).to include(failed.user.tutorial_name)
        expect(rendered_content).to include(unmarked.user.tutorial_name)
      end

      it "shows check icon for pass" do
        render_inline(component)
        expect(rendered_content).to include("bi-check-circle-fill")
      end

      it "shows x icon for fail" do
        render_inline(component)
        expect(rendered_content).to include("bi-x-circle-fill")
      end

      it "shows em-dash for unmarked" do
        expect(component.value_display(unmarked)).to eq("\u2014")
      end

      it "returns correct met? results" do
        expect(component.met?(passed)).to be(true)
        expect(component.met?(failed)).to be(false)
        expect(component.met?(unmarked)).to be(false)
      end

      it "returns correct status badges" do
        expect(component.status_badge(passed)).to eq(:met)
        expect(component.status_badge(failed)).to eq(:not_met)
        expect(component.status_badge(unmarked)).to eq(:unmarked)
      end

      it "counts marked participations" do
        expect(component.marked_count).to eq(2)
      end

      it "counts met participations" do
        expect(component.met_count).to eq(1)
      end

      it "renders the summary line" do
        render_inline(component)
        expect(rendered_content).to include("2 / 3")
      end
    end
  end

  context "with a numeric achievement" do
    let(:achievement) do
      create(:achievement, :numeric, lecture: lecture, threshold: 15)
    end
    let(:assessment) do
      achievement.ensure_assessment!(
        requires_points: false, requires_submission: false
      )
    end
    let(:component) { described_class.new(achievement: achievement) }

    let!(:above) do
      create(:assessment_participation,
             assessment: assessment,
             grade_text: "18")
    end
    let!(:below) do
      create(:assessment_participation,
             assessment: assessment,
             grade_text: "10")
    end

    it "displays value with threshold comparison" do
      expect(component.value_display(above)).to eq("18 / 15")
      expect(component.value_display(below)).to eq("10 / 15")
    end

    it "evaluates met? correctly" do
      expect(component.met?(above)).to be(true)
      expect(component.met?(below)).to be(false)
    end
  end

  context "with a percentage achievement" do
    let(:achievement) do
      create(:achievement, :percentage, lecture: lecture, threshold: 80.0)
    end
    let(:assessment) do
      achievement.ensure_assessment!(
        requires_points: false, requires_submission: false
      )
    end
    let(:component) { described_class.new(achievement: achievement) }

    let!(:above) do
      create(:assessment_participation,
             assessment: assessment,
             grade_text: "85.0")
    end
    let!(:below) do
      create(:assessment_participation,
             assessment: assessment,
             grade_text: "60.0")
    end

    it "displays value with percentage formatting" do
      expect(component.value_display(above)).to eq("85.0% / 80.0%")
      expect(component.value_display(below)).to eq("60.0% / 80.0%")
    end

    it "evaluates met? correctly" do
      expect(component.met?(above)).to be(true)
      expect(component.met?(below)).to be(false)
    end
  end
end
