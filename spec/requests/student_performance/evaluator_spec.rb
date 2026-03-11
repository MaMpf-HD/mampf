require "rails_helper"

RSpec.describe("StudentPerformance::Evaluator", type: :request) do
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

  describe "POST /lectures/:lecture_id/performance/evaluator/bulk_proposals" do
    context "as an editor" do
      before { sign_in editor }

      context "without an active rule" do
        it "redirects with an alert" do
          post bulk_proposals_lecture_student_performance_evaluator_path(lecture)
          expect(response).to redirect_to(
            lecture_student_performance_records_path(lecture)
          )
          follow_redirect!
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.no_rule")
          )
        end
      end

      context "with an active rule" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        context "with no records" do
          it "returns http success" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response).to have_http_status(:success)
          end

          it "shows the empty state" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.bulk_proposals.empty")
            )
          end
        end

        context "with records" do
          let!(:passing_user) { FactoryBot.create(:confirmed_user) }
          let!(:failing_user) { FactoryBot.create(:confirmed_user) }

          let!(:passing_record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: passing_user,
                              percentage_materialized: 60,
                              points_total_materialized: 60,
                              points_max_materialized: 100)
          end

          let!(:failing_record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: failing_user,
                              percentage_materialized: 40,
                              points_total_materialized: 40,
                              points_max_materialized: 100)
          end

          it "returns http success" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response).to have_http_status(:success)
          end

          it "shows both students" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response.body).to include(passing_user.tutorial_name)
            expect(response.body).to include(failing_user.tutorial_name)
          end

          it "shows passed and failed badges" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.passed")
            )
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.failed")
            )
          end

          it "shows correct summary counts" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response.body).to include("1")
          end

          it "shows the info alert" do
            post bulk_proposals_lecture_student_performance_evaluator_path(
              lecture
            )
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.bulk_proposals.info")
            )
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post bulk_proposals_lecture_student_performance_evaluator_path(lecture)
        expect(response).to redirect_to(root_url)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post bulk_proposals_lecture_student_performance_evaluator_path(lecture)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
        post bulk_proposals_lecture_student_performance_evaluator_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /lectures/:id/performance/evaluator/preview_rule_change" do
    let(:path) do
      preview_rule_change_lecture_student_performance_evaluator_path(lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      context "without an active rule" do
        it "redirects with an alert" do
          post path
          expect(response).to redirect_to(
            lecture_student_performance_records_path(lecture)
          )
        end
      end

      context "with an active rule at 50%" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        context "with no records" do
          it "returns http success" do
            post path, params: { preview: { min_percentage: 30 } }
            expect(response).to have_http_status(:success)
          end

          it "shows no-changes message" do
            post path, params: { preview: { min_percentage: 30 } }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.preview_rule_change.no_changes")
            )
          end
        end

        context "with records" do
          let!(:passing_user) { FactoryBot.create(:confirmed_user) }
          let!(:borderline_user) { FactoryBot.create(:confirmed_user) }
          let!(:failing_user) { FactoryBot.create(:confirmed_user) }

          before do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: passing_user,
                              percentage_materialized: 60,
                              points_total_materialized: 60,
                              points_max_materialized: 100)

            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: borderline_user,
                              percentage_materialized: 45,
                              points_total_materialized: 45,
                              points_max_materialized: 100)

            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: failing_user,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100)
          end

          it "shows newly passed when lowering threshold" do
            post path, params: { preview: { min_percentage: 40 } }
            expect(response).to have_http_status(:success)
            expect(response.body).to include(borderline_user.tutorial_name)
          end

          it "shows the apply button when threshold differs" do
            post path, params: { preview: { min_percentage: 40 } }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.preview_rule_change.apply_threshold")
            )
          end

          it "does not show the apply button when threshold is unchanged" do
            post path, params: { preview: { min_percentage: 50 } }
            expect(response.body).not_to include(
              I18n.t("student_performance.evaluator.preview_rule_change.apply_threshold")
            )
          end

          it "includes hidden achievement IDs in the apply form" do
            achievement = FactoryBot.create(:achievement, :boolean,
                                            lecture: lecture,
                                            title: "Midterm")
            FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: achievement)
            post path, params: { preview: { min_percentage: 40 } }
            expect(response.body).to include(
              "rule[achievement_ids][]"
            )
            expect(response.body).to include(achievement.id.to_s)
          end

          it "does not include students unaffected by the change" do
            post path, params: { preview: { min_percentage: 40 } }
            expect(response.body).not_to include(passing_user.tutorial_name)
            expect(response.body).not_to include(failing_user.tutorial_name)
          end

          it "shows newly failed when raising threshold" do
            post path, params: { preview: { min_percentage: 65 } }
            expect(response.body).to include(passing_user.tutorial_name)
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.failed")
            )
          end

          it "shows no changes when threshold is unchanged" do
            post path, params: { preview: { min_percentage: 50 } }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.preview_rule_change.no_changes")
            )
          end

          it "uses the current rule if no params given" do
            post path
            expect(response).to have_http_status(:success)
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.preview_rule_change.no_changes")
            )
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post path
        expect(response).to redirect_to(root_url)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
        post path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:id/performance/evaluator/single_proposal" do
    let(:path) do
      single_proposal_lecture_student_performance_evaluator_path(lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      context "without an active rule" do
        let!(:record) do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: student,
                            percentage_materialized: 60,
                            points_total_materialized: 60,
                            points_max_materialized: 100)
        end

        it "redirects with an alert" do
          get path, params: { record_id: record.id }
          expect(response).to redirect_to(
            lecture_student_performance_records_path(lecture)
          )
        end
      end

      context "with an active rule" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        context "with a missing record_id" do
          it "redirects with an alert" do
            get path, params: { record_id: 0 }
            expect(response).to redirect_to(
              lecture_student_performance_records_path(lecture)
            )
          end
        end

        context "with a passing student" do
          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 75,
                              points_total_materialized: 75,
                              points_max_materialized: 100)
          end

          it "returns http success" do
            get path, params: { record_id: record.id }
            expect(response).to have_http_status(:success)
          end

          it "shows the student name" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(student.tutorial_name)
          end

          it "shows the passed badge" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.passed")
            )
          end

          it "shows the points check section" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.single_proposal.points_check")
            )
          end
        end

        context "with a failing student" do
          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100)
          end

          it "shows the failed badge" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.failed")
            )
          end
        end

        context "with no achievements required" do
          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 60,
                              points_total_materialized: 60,
                              points_max_materialized: 100)
          end

          it "shows the no-achievements message" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.single_proposal.no_achievements_required")
            )
          end
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get path
        expect(response).to redirect_to(root_url)
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        get path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
        get path
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
