require "rails_helper"

RSpec.describe("StudentPerformance::Rules", type: :request) do
  let(:lecture) { FactoryBot.create(:lecture, locale: I18n.default_locale) }
  let(:editor) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  before do
    Flipper.enable(:student_performance)
    FactoryBot.create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end

  after do
    Flipper.disable(:student_performance)
  end

  describe "GET /lectures/:lecture_id/performance/rules" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_rules_path(lecture)
        expect(response).to have_http_status(:success)
      end

      context "without a configured rule" do
        it "shows the no-rule message" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.no_rule")
          )
        end
      end

      context "with an active rule using percentage threshold" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture)
        end

        it "shows the percentage threshold" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include("50")
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.of_total_points")
          )
        end

        it "shows the edit hint" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.edit_hint")
          )
        end
      end

      context "with an active rule using absolute points" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_absolute_points,
                            lecture: lecture)
        end

        it "shows the absolute point threshold" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include("60")
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.points_absolute")
          )
        end
      end

      context "with required achievements" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture)
        end
        let!(:achievement) do
          FactoryBot.create(:achievement, :boolean,
                            lecture: lecture,
                            title: "Blackboard Presentation")
        end
        let!(:rule_achievement) do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule,
                            achievement: achievement)
        end

        it "shows the achievement title" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include("Blackboard Presentation")
        end

        it "shows the achievement value type badge" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.value_types.boolean")
          )
        end
      end

      context "with an inactive rule only" do
        before do
          FactoryBot.create(:student_performance_rule,
                            :with_percentage,
                            lecture: lecture,
                            active: false)
        end

        it "shows the no-rule message" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.no_rule")
          )
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get lecture_student_performance_rules_path(lecture)
        expect(response).to redirect_to(root_url)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get lecture_student_performance_rules_path(lecture)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
        get lecture_student_performance_rules_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
