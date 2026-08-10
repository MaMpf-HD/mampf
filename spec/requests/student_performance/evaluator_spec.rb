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
            expect(response.body).to include(CGI.escapeHTML(student.tutorial_name))
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

        context "when the marking still outstanding could carry the student" do
          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100,
                              points_max_pending_materialized: 40)
          end

          it "does not call the points check failed" do
            get path, params: { record_id: record.id }
            expect(response.body).not_to include(
              I18n.t("student_performance.evaluator.status.failed")
            )
          end

          it "names the outstanding marking as the reason" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.deferral.points_pending")
            )
          end
        end

        context "when there are no points to measure" do
          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 0,
                              points_total_materialized: 0,
                              points_max_materialized: 0)
          end

          it "says so rather than calling the student failed" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.deferral.points_not_measurable")
            )
            expect(response.body).not_to include(
              I18n.t("student_performance.evaluator.status.failed")
            )
          end
        end

        context "when a missed achievement settles an otherwise open case" do
          let(:achievement) { FactoryBot.create(:achievement, lecture: lecture) }

          let!(:record) do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: student,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100,
                              points_max_pending_materialized: 40)
          end

          before do
            FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: achievement)
          end

          it "keeps the points check open even though the verdict is failed" do
            get path, params: { record_id: record.id }
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.deferral.points_pending")
            )
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
