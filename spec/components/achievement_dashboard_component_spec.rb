require "rails_helper"

RSpec.describe(AchievementDashboardComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let!(:achievement) do
    create(:achievement, lecture: lecture, title: "Blackboard Talk")
  end

  let(:component) do
    described_class.new(achievement: achievement, lecture: lecture)
  end

  describe "rendering" do
    before { render_inline(component) }

    it "renders the achievement title" do
      expect(rendered_content).to include("Blackboard Talk")
    end

    it "renders a back link" do
      expect(rendered_content).to include(I18n.t("back"))
      expect(rendered_content).to include("tab=achievements")
    end

    it "renders the settings form" do
      expect(rendered_content).to include("achievement[title]")
    end
  end

  describe "#grading_enabled?" do
    context "without assessment_grading flag" do
      it "returns false" do
        expect(component.grading_enabled?).to be(false)
      end
    end

    context "with assessment_grading flag" do
      before { Flipper.enable(:assessment_grading) }
      after { Flipper.disable(:assessment_grading) }

      context "when achievement has no assessment" do
        it "returns false" do
          expect(component.grading_enabled?).to be(false)
        end
      end

      context "when achievement has an assessment" do
        before do
          achievement.ensure_assessment!(
            requires_points: false, requires_submission: false
          )
        end

        it "returns true" do
          expect(component.grading_enabled?).to be(true)
        end

        it "renders the marking section" do
          render_inline(component)
          expect(rendered_content).to include(I18n.t("assessment.grading"))
        end
      end
    end
  end

  describe "#dom_prefix" do
    it "includes the achievement id" do
      expect(component.dom_prefix).to eq(
        "dashboard-achievement-#{achievement.id}"
      )
    end
  end

  describe "#back_path" do
    it "points to the assessments overview with achievements tab" do
      render_inline(component)
      expect(component.back_path).to include("tab=achievements")
    end
  end
end
