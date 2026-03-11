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

        it "shows the edit button" do
          get lecture_student_performance_rules_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.edit_button")
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

  describe "GET /lectures/:lecture_id/performance/rules/edit" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_lecture_student_performance_rules_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "shows the edit form title" do
        get edit_lecture_student_performance_rules_path(lecture)
        expect(response.body).to include(
          I18n.t("student_performance.rules.edit.title")
        )
      end

      context "with an existing rule" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 42)
        end

        it "pre-fills the percentage value" do
          get edit_lecture_student_performance_rules_path(lecture)
          expect(response.body).to include("42")
        end
      end

      context "with achievements" do
        let!(:achievement) do
          FactoryBot.create(:achievement, :boolean,
                            lecture: lecture,
                            title: "Homework Pass")
        end

        it "shows available achievements as checkboxes" do
          get edit_lecture_student_performance_rules_path(lecture)
          expect(response.body).to include("Homework Pass")
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get edit_lecture_student_performance_rules_path(lecture)
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "PATCH /lectures/:lecture_id/performance/rules" do
    context "as an editor" do
      before { sign_in editor }

      it "creates a new rule with percentage threshold" do
        expect do
          patch(lecture_student_performance_rules_path(lecture),
                params: { rule: {
                  threshold_mode: "percentage",
                  min_percentage: "50"
                } })
        end.to change(StudentPerformance::Rule, :count).by(1)

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        rule = StudentPerformance::Rule.find_by(lecture: lecture)
        expect(rule.min_percentage).to eq(50)
        expect(rule.min_points_absolute).to be_nil
        expect(rule).to be_active
      end

      it "creates a rule with absolute points threshold" do
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "absolute",
                min_points_absolute: "75"
              } }
        rule = StudentPerformance::Rule.find_by(lecture: lecture)
        expect(rule.min_points_absolute).to eq(75)
        expect(rule.min_percentage).to be_nil
      end

      it "updates an existing rule" do
        rule = FactoryBot.create(:student_performance_rule, :active,
                                 :with_percentage,
                                 lecture: lecture,
                                 min_percentage: 40)
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "percentage",
                min_percentage: "60"
              } }
        rule.reload
        expect(rule.min_percentage).to eq(60)
      end

      it "switches from percentage to absolute" do
        rule = FactoryBot.create(:student_performance_rule, :active,
                                 :with_percentage,
                                 lecture: lecture,
                                 min_percentage: 50)
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "absolute",
                min_points_absolute: "80"
              } }
        rule.reload
        expect(rule.min_percentage).to be_nil
        expect(rule.min_points_absolute).to eq(80)
      end

      it "shows a success flash" do
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "percentage",
                min_percentage: "50"
              } }
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.rules.flash.updated")
        )
      end

      context "with achievements" do
        let!(:ach_a) do
          FactoryBot.create(:achievement, :boolean,
                            lecture: lecture, title: "Presentation")
        end
        let!(:ach_b) do
          FactoryBot.create(:achievement, :boolean,
                            lecture: lecture, title: "Homework")
        end

        it "adds selected achievements to the rule" do
          patch lecture_student_performance_rules_path(lecture),
                params: { rule: {
                  threshold_mode: "percentage",
                  min_percentage: "50",
                  achievement_ids: [ach_a.id.to_s, ach_b.id.to_s]
                } }
          rule = StudentPerformance::Rule.find_by(lecture: lecture)
          expect(rule.required_achievements).to contain_exactly(ach_a, ach_b)
        end

        it "removes deselected achievements" do
          rule = FactoryBot.create(:student_performance_rule, :active,
                                   :with_percentage,
                                   lecture: lecture)
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: ach_a)
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: ach_b)
          patch lecture_student_performance_rules_path(lecture),
                params: { rule: {
                  threshold_mode: "percentage",
                  min_percentage: "50",
                  achievement_ids: [ach_a.id.to_s]
                } }
          rule.reload
          expect(rule.required_achievements).to contain_exactly(ach_a)
        end

        it "clears all achievements when none selected" do
          rule = FactoryBot.create(:student_performance_rule, :active,
                                   :with_percentage,
                                   lecture: lecture)
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: ach_a)
          patch lecture_student_performance_rules_path(lecture),
                params: { rule: {
                  threshold_mode: "percentage",
                  min_percentage: "50"
                } }
          rule.reload
          expect(rule.required_achievements).to be_empty
        end

        it "ignores achievement IDs that do not belong to this lecture" do
          other_lecture = FactoryBot.create(:lecture, :with_organizational_stuff)
          foreign_ach = FactoryBot.create(:achievement, :boolean,
                                          lecture: other_lecture,
                                          title: "Foreign")
          patch lecture_student_performance_rules_path(lecture),
                params: { rule: {
                  threshold_mode: "percentage",
                  min_percentage: "50",
                  achievement_ids: [ach_a.id.to_s, foreign_ach.id.to_s]
                } }
          rule = StudentPerformance::Rule.find_by(lecture: lecture)
          expect(rule.required_achievements).to contain_exactly(ach_a)
        end
      end

      it "renders edit with errors for invalid percentage" do
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "percentage",
                min_percentage: "150"
              } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include(
          I18n.t("student_performance.rules.edit.title")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        patch lecture_student_performance_rules_path(lecture),
              params: { rule: {
                threshold_mode: "percentage",
                min_percentage: "50"
              } }
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
