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

    it "renders the original threshold value in fixed-point notation" do
      achievement.update!(value_type: :percentage,
                          threshold: BigDecimal("0.8e2"))

      render_inline(component)

      expect(rendered_content).to include(
        %(data-achievement-form-original-threshold-value="80.0")
      )
      expect(rendered_content).not_to include(
        %(data-achievement-form-original-threshold-value="0.8e2")
      )
    end
  end

  describe "the delete button" do
    before { allow(vc_test_controller).to receive(:current_user).and_return(teacher) }

    it "stands under the settings, not beside the back link" do
      page = render_inline(component)

      header = page.css(".d-flex.justify-content-between").first
      expect(header.css("form[method=post]")).to be_empty
      expect(page.css("form[action$='#{achievement.id}'] button[type=submit]").text)
        .to include(I18n.t("basics.delete"))
    end

    it "is locked with the reason once a value is entered" do
      student = create(:confirmed_user)
      create(:lecture_membership, lecture: lecture, user: student)
      achievement.assessment.assessment_participations.find_by!(user: student)
                 .update!(grade_text: Achievement::PASSED)

      page = render_inline(component)

      expect(page.css("button[disabled]").text).to include(I18n.t("basics.delete"))
      expect(page.css("[data-bs-toggle=tooltip]").first["title"])
        .to eq(I18n.t("assessment.achievement_not_destructible.has_values"))
    end
  end

  describe "#grading_enabled?" do
    context "depending on the assessment" do
      context "when achievement has no assessment" do
        # Achievements build one on create, so only older data lacks it.
        before do
          achievement.assessment&.destroy
          achievement.reload
        end

        it "returns false" do
          expect(component.grading_enabled?).to be(false)
        end

        it "still offers the delete button" do
          render_inline(component)
          expect(rendered_content).to include(I18n.t("basics.delete"))
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
