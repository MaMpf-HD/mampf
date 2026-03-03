require "rails_helper"

RSpec.describe("StudentPerformance::Certifications", type: :request) do
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

  describe "GET /lectures/:lecture_id/performance/certifications" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "shows the dashboard title" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response.body).to include(
          I18n.t("student_performance.certifications.index.title")
        )
      end

      it "shows zero counts when no data exists" do
        get lecture_student_performance_certifications_path(lecture)
        body = response.body
        expect(body).to include("0")
      end

      context "with certifications" do
        let(:user_a) { FactoryBot.create(:confirmed_user) }
        let(:user_b) { FactoryBot.create(:confirmed_user) }
        let(:user_c) { FactoryBot.create(:confirmed_user) }

        let!(:cert_passed) do
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture, user: user_a)
        end

        let!(:cert_failed) do
          FactoryBot.create(:student_performance_certification, :failed,
                            lecture: lecture, user: user_b)
        end

        let!(:cert_pending) do
          FactoryBot.create(:student_performance_certification, :pending,
                            lecture: lecture, user: user_c)
        end

        it "shows correct summary counts" do
          get lecture_student_performance_certifications_path(lecture)
          body = response.body
          expect(body).to include(
            I18n.t("student_performance.certifications.status.passed")
          )
          expect(body).to include(
            I18n.t("student_performance.certifications.status.failed")
          )
          expect(body).to include(
            I18n.t("student_performance.certifications.status.pending")
          )
        end

        it "shows certification badges for each student" do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: user_a)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: user_b)
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(user_a.tutorial_name)
          expect(response.body).to include(user_b.tutorial_name)
        end

        context "with status filter" do
          before do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user_a)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user_b)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user_c)
          end

          it "filters by passed status" do
            get lecture_student_performance_certifications_path(
              lecture, status: "passed"
            )
            expect(response.body).to include(user_a.tutorial_name)
            expect(response.body).not_to include(user_b.tutorial_name)
            expect(response.body).not_to include(user_c.tutorial_name)
          end

          it "filters by failed status" do
            get lecture_student_performance_certifications_path(
              lecture, status: "failed"
            )
            expect(response.body).not_to include(user_a.tutorial_name)
            expect(response.body).to include(user_b.tutorial_name)
            expect(response.body).not_to include(user_c.tutorial_name)
          end

          it "filters by pending status" do
            get lecture_student_performance_certifications_path(
              lecture, status: "pending"
            )
            expect(response.body).not_to include(user_a.tutorial_name)
            expect(response.body).not_to include(user_b.tutorial_name)
            expect(response.body).to include(user_c.tutorial_name)
          end

          it "filters by uncertified status" do
            uncertified_user = FactoryBot.create(:confirmed_user)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: uncertified_user)
            get lecture_student_performance_certifications_path(
              lecture, status: "uncertified"
            )
            expect(response.body).to include(uncertified_user.tutorial_name)
            expect(response.body).not_to include(user_a.tutorial_name)
            expect(response.body).not_to include(user_b.tutorial_name)
            expect(response.body).not_to include(user_c.tutorial_name)
          end
        end
      end

      context "with an active rule and proposals" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        let(:passing_user) { FactoryBot.create(:confirmed_user) }
        let(:failing_user) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: passing_user,
                            percentage_materialized: 60,
                            points_total_materialized: 60,
                            points_max_materialized: 100)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: failing_user,
                            percentage_materialized: 40,
                            points_total_materialized: 40,
                            points_max_materialized: 100)
        end

        it "shows proposed status for students" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.status.passed")
          )
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.status.failed")
          )
        end

        it "shows the active rule info" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.index.rule_info")
          )
        end

        it "shows the bulk accept button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.index.bulk_accept")
          )
        end

        it "shows the try different threshold button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.preview_rule_change.try_threshold")
          )
        end
      end

      context "without a rule" do
        it "shows the no-rule warning" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.no_rule")
          )
        end

        it "does not show the bulk accept button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).not_to include(
            I18n.t("student_performance.certifications.index.bulk_accept")
          )
        end
      end

      context "with a manual override certification" do
        let(:user_m) { FactoryBot.create(:confirmed_user) }

        let!(:manual_cert) do
          FactoryBot.create(:student_performance_certification, :passed,
                            :manual,
                            lecture: lecture,
                            user: user_m,
                            note: "Medical exemption")
        end

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: user_m)
        end

        it "shows the manual override indicator" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include("bi-pencil-square")
        end

        it "shows the override note" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include("Medical exemption")
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response).to redirect_to(root_url)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/certifications" do
    let!(:rule) do
      FactoryBot.create(:student_performance_rule, :active,
                        :with_percentage,
                        lecture: lecture,
                        min_percentage: 50)
    end

    let(:target_user) { FactoryBot.create(:confirmed_user) }

    before do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture,
                        user: target_user,
                        percentage_materialized: 60,
                        points_total_materialized: 60,
                        points_max_materialized: 100)
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a certification and redirects" do
        expect do
          post(lecture_student_performance_certifications_path(lecture),
               params: { certification: {
                 user_id: target_user.id, status: "passed"
               } })
        end.to change(StudentPerformance::Certification, :count).by(1)

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        cert = StudentPerformance::Certification.last
        expect(cert.status).to eq("passed")
        expect(cert.source).to eq("computed")
        expect(cert.certified_by).to eq(editor)
        expect(cert.rule).to eq(rule)
      end

      it "updates an existing pending certification" do
        existing = FactoryBot.create(
          :student_performance_certification, :pending,
          lecture: lecture, user: target_user
        )
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: target_user.id, status: "passed"
             } }
        existing.reload
        expect(existing.status).to eq("passed")
        expect(existing.certified_by).to eq(editor)
      end

      it "redirects with alert when no rule exists" do
        rule.update!(active: false)
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: target_user.id, status: "passed"
             } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.evaluator.no_rule")
        )
      end

      it "redirects with alert for invalid user" do
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: -1, status: "passed"
             } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.errors.no_member")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: target_user.id, status: "passed"
             } }
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/certifications/bulk_accept" do
    let!(:rule) do
      FactoryBot.create(:student_performance_rule, :active,
                        :with_percentage,
                        lecture: lecture,
                        min_percentage: 50)
    end

    let(:passing_user) { FactoryBot.create(:confirmed_user) }
    let(:failing_user) { FactoryBot.create(:confirmed_user) }

    before do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture,
                        user: passing_user,
                        percentage_materialized: 60,
                        points_total_materialized: 60,
                        points_max_materialized: 100)
      FactoryBot.create(:student_performance_record,
                        lecture: lecture,
                        user: failing_user,
                        percentage_materialized: 40,
                        points_total_materialized: 40,
                        points_max_materialized: 100)
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates certifications for all students" do
        expect do
          post(bulk_accept_lecture_student_performance_certifications_path(
                 lecture
               ))
        end.to change(StudentPerformance::Certification, :count).by(2)

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
      end

      it "sets correct statuses based on proposals" do
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        passed = StudentPerformance::Certification.find_by(
          user: passing_user, lecture: lecture
        )
        failed = StudentPerformance::Certification.find_by(
          user: failing_user, lecture: lecture
        )
        expect(passed.status).to eq("passed")
        expect(passed.source).to eq("computed")
        expect(passed.certified_by).to eq(editor)
        expect(failed.status).to eq("failed")
      end

      it "skips manual overrides" do
        manual_cert = FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: passing_user,
          note: "Special case"
        )
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        manual_cert.reload
        expect(manual_cert.source).to eq("manual")
        expect(manual_cert.note).to eq("Special case")
      end

      it "updates existing computed certifications" do
        existing = FactoryBot.create(
          :student_performance_certification, :pending,
          lecture: lecture, user: passing_user
        )
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        existing.reload
        expect(existing.status).to eq("passed")
        expect(existing.certified_by).to eq(editor)
      end

      it "shows the count in the flash message" do
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        follow_redirect!
        expect(response.body).to include("2")
      end

      it "redirects with alert when no rule exists" do
        rule.update!(active: false)
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.evaluator.no_rule")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(root_url)
      end
    end
  end
end
