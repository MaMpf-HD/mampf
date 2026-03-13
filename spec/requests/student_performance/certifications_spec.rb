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
            I18n.t("student_performance.certifications.index.passed")
          )
          expect(body).to include(
            I18n.t("student_performance.certifications.index.failed")
          )
          expect(body).to include(
            I18n.t("student_performance.certifications.index.uncertified")
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

          it "filters by stale status" do
            record_a = StudentPerformance::Record.find_by(
              lecture: lecture, user: user_a
            )
            # rubocop:disable Rails/SkipsModelValidations
            record_a.update_columns(computed_at: 1.hour.ago)
            cert_passed.update_columns(certified_at: 2.hours.ago)

            record_b = StudentPerformance::Record.find_by(
              lecture: lecture, user: user_b
            )
            record_b.update_columns(computed_at: 3.hours.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(
              lecture, status: "stale"
            )
            expect(response.body).to include(user_a.tutorial_name)
            expect(response.body).not_to include(user_b.tutorial_name)
          end
        end

        context "with stale banners" do
          let!(:rule) do
            FactoryBot.create(:student_performance_rule, :active,
                              :with_percentage,
                              lecture: lecture,
                              min_percentage: 50)
          end

          it "shows the rule-change banner when rule was updated" do
            cert_passed.update!(rule: rule)
            # rubocop:disable Rails/SkipsModelValidations
            cert_passed.update_columns(certified_at: 2.hours.ago)
            rule.update_columns(updated_at: 1.hour.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(
              I18n.t("student_performance.certifications.index.reevaluate_rules")
            )
          end

          it "shows the data-change banner when record was recomputed" do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user_a,
                              computed_at: 1.hour.ago)
            # rubocop:disable Rails/SkipsModelValidations
            cert_passed.update_columns(certified_at: 2.hours.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(
              I18n.t("student_performance.certifications.index.reevaluate_data")
            )
          end

          it "shows the manual-review banner for stale manual overrides" do
            manual_cert = FactoryBot.create(
              :student_performance_certification, :passed, :manual,
              lecture: lecture,
              user: FactoryBot.create(:confirmed_user),
              rule: rule,
              note: "Special"
            )
            # rubocop:disable Rails/SkipsModelValidations
            manual_cert.update_columns(certified_at: 2.hours.ago)
            rule.update_columns(updated_at: 1.hour.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(
              I18n.t(
                "student_performance.certifications.index" \
                ".stale_rule_manual_warning",
                count: 1
              )
            )
          end

          it "does not show reconcile button for manual-only staleness" do
            manual_cert = FactoryBot.create(
              :student_performance_certification, :passed, :manual,
              lecture: lecture,
              user: FactoryBot.create(:confirmed_user),
              rule: rule,
              note: "Override"
            )
            # rubocop:disable Rails/SkipsModelValidations
            manual_cert.update_columns(certified_at: 2.hours.ago)
            rule.update_columns(updated_at: 1.hour.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).not_to include(
              I18n.t(
                "student_performance.certifications.index.reevaluate_rules"
              )
            )
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

        it "shows the edit rules button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.edit_button")
          )
        end

        context "when rule has required achievements" do
          let!(:achievement) do
            FactoryBot.create(:achievement, lecture: lecture,
                                            title: "Homework A")
          end

          before do
            FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: achievement)
          end

          it "shows the required achievements in the rule info" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include("Homework A")
            expect(response.body).to include(
              I18n.t("student_performance.certifications.index" \
                     ".required_achievements_label")
            )
          end
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

        it "shows proposal counts in the bulk accept button" do
          get lecture_student_performance_certifications_path(lecture)
          body = response.body
          expect(body).to include(
            I18n.t("student_performance.certifications.index.bulk_accept")
          )
          expect(body).to include("1")
          expect(body).to include(
            I18n.t("student_performance.certifications.index.proposed_passed")
          )
          expect(body).to include(
            I18n.t("student_performance.certifications.index.proposed_failed")
          )
        end

        it "shows the percentage column (not points) for a percentage rule" do
          get lecture_student_performance_certifications_path(lecture)
          body = response.body
          expect(body).to include(
            I18n.t("student_performance.records.columns.percentage")
          )
          expect(body).not_to include(
            ">#{I18n.t("student_performance.records.columns.points")}<"
          )
        end
      end

      context "with absolute-points rule and records" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_absolute_points,
                            lecture: lecture,
                            min_points_absolute: 60)
        end

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: FactoryBot.create(:confirmed_user),
                            percentage_materialized: 70,
                            points_total_materialized: 70,
                            points_max_materialized: 100)
        end

        it "shows the points column (not percentage)" do
          get lecture_student_performance_certifications_path(lecture)
          body = response.body
          expect(body).to include(
            I18n.t("student_performance.records.columns.points")
          )
          expect(body).not_to include(
            ">#{I18n.t("student_performance.records.columns.percentage")}<"
          )
        end
      end

      context "with rule and achievements" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        let!(:achievement) do
          FactoryBot.create(:achievement, lecture: lecture,
                                          title: "Homework A")
        end

        let(:student) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: achievement)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: student,
                            percentage_materialized: 80,
                            points_total_materialized: 80,
                            points_max_materialized: 100,
                            achievements_met_ids: [achievement.id])
        end

        it "renders the achievement column header" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include("Homework A")
        end

        it "renders met icon for met achievement" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include("bi-check-lg")
        end
      end

      context "when all students are already certified" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        let(:certified_user) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: certified_user,
                            percentage_materialized: 60,
                            points_total_materialized: 60,
                            points_max_materialized: 100)
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture,
                            user: certified_user,
                            certified_by: editor)
        end

        it "does not show the bulk accept button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).not_to include(
            I18n.t("student_performance.certifications.index.bulk_accept")
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

        it "shows the setup rule button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.index.setup_rule")
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
        expect(cert.source).to eq("manual")
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

      it "rejects a user who has no record in this lecture" do
        other_user = FactoryBot.create(:confirmed_user)
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: other_user.id, status: "passed"
             } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.errors.no_member")
        )
        expect(StudentPerformance::Certification.find_by(
                 user: other_user, lecture: lecture
               )).to be_nil
      end

      it "rejects overwriting a manual certification" do
        FactoryBot.create(:student_performance_certification, :manual,
                          lecture: lecture,
                          user: target_user,
                          certified_by: editor)
        post lecture_student_performance_certifications_path(lecture),
             params: { certification: {
               user_id: target_user.id, status: "passed"
             } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t(
            "student_performance.certifications.flash.manual_exists"
          )
        )
        cert = StudentPerformance::Certification.find_by(
          user: target_user, lecture: lecture
        )
        expect(cert.source).to eq("manual")
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

      it "skips certifications whose status differs from the proposal" do
        divergent = FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: lecture, user: failing_user,
          source: :computed, certified_by: editor
        )
        post bulk_accept_lecture_student_performance_certifications_path(
          lecture
        )
        divergent.reload
        expect(divergent.status).to eq("passed")
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

  describe "PATCH /lectures/:lecture_id/performance/certifications/:id" do
    let(:target_user) { FactoryBot.create(:confirmed_user) }

    let!(:cert) do
      FactoryBot.create(:student_performance_certification, :passed,
                        lecture: lecture, user: target_user)
    end

    context "as an editor" do
      before { sign_in editor }

      it "updates the certification as manual override" do
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "failed", note: "Grade appeal accepted"
              } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        cert.reload
        expect(cert.status).to eq("failed")
        expect(cert.source).to eq("manual")
        expect(cert.note).to eq("Grade appeal accepted")
        expect(cert.certified_by).to eq(editor)
        expect(cert.certified_at).to be_within(5.seconds).of(Time.current)
      end

      it "shows a success flash message" do
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "passed", note: "Re-evaluation"
              } }
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.certifications.flash.updated")
        )
      end

      it "allows override without a note" do
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "failed", note: ""
              } }
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        cert.reload
        expect(cert.status).to eq("failed")
        expect(cert.source).to eq("manual")
      end

      it "preserves the existing rule association" do
        rule = FactoryBot.create(:student_performance_rule, :active,
                                 :with_percentage,
                                 lecture: lecture,
                                 min_percentage: 50)
        cert.update!(rule: rule)
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "failed", note: "Override reason"
              } }
        cert.reload
        expect(cert.rule).to eq(rule)
      end

      it "cannot override a certification from another lecture" do
        other_lecture = FactoryBot.create(:lecture)
        other_cert = FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: other_lecture, user: target_user
        )
        patch lecture_student_performance_certification_path(
          lecture, other_cert
        ),
              params: { certification: {
                status: "failed", note: "Sneaky"
              } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "failed", note: "Trying to hack"
              } }
        expect(response).to redirect_to(root_url)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        patch lecture_student_performance_certification_path(lecture, cert),
              params: { certification: {
                status: "failed", note: "Anon"
              } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/certifications/bulk_reevaluate" do
    let!(:rule) do
      FactoryBot.create(:student_performance_rule, :active,
                        :with_percentage,
                        lecture: lecture,
                        min_percentage: 50)
    end

    let(:user_a) { FactoryBot.create(:confirmed_user) }
    let(:user_b) { FactoryBot.create(:confirmed_user) }

    before do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: user_a,
                        percentage_materialized: 60,
                        points_total_materialized: 60,
                        points_max_materialized: 100,
                        computed_at: 3.hours.ago)
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: user_b,
                        percentage_materialized: 40,
                        points_total_materialized: 40,
                        points_max_materialized: 100,
                        computed_at: 3.hours.ago)
    end

    context "as an editor" do
      before { sign_in editor }

      it "re-evaluates stale certifications" do
        cert_a = FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: lecture, user: user_a, rule: rule,
          certified_at: 4.hours.ago
        )
        cert_b = FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: lecture, user: user_b, rule: rule,
          certified_at: 4.hours.ago
        )
        rule.update!(min_percentage: 50)

        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        cert_a.reload
        cert_b.reload
        expect(cert_a.status).to eq("passed")
        expect(cert_b.status).to eq("failed")
        expect(cert_a.certified_at).to be_within(5.seconds).of(Time.current)
      end

      it "skips manual overrides" do
        cert = FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: user_b, rule: rule,
          certified_at: 4.hours.ago
        )
        rule.update!(min_percentage: 50)

        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )

        cert.reload
        expect(cert.status).to eq("passed")
        expect(cert.source).to eq("manual")
      end

      it "shows a flash message with count" do
        FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: lecture, user: user_a, rule: rule,
          certified_at: 4.hours.ago
        )
        rule.update!(min_percentage: 50)

        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )
        follow_redirect!
        expect(response.body).to include(
          I18n.t("student_performance.certifications.flash.reevaluated",
                 count: 1)
        )
      end

      it "redirects with alert when no rule exists" do
        rule.destroy!
        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(root_url)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
