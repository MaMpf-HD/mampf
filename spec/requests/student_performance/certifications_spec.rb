require "rails_helper"

RSpec.describe("StudentPerformance::Certifications", type: :request) do
  let(:lecture) { FactoryBot.create(:lecture, locale: I18n.default_locale) }
  let(:editor) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  before do
    FactoryBot.create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    # Every example below is about a term whose assignments have all been
    # created; the examples about the state before that say so themselves.
    lecture.update!(assignments_complete: true)
    lecture.reload
  end
  describe "GET /lectures/:lecture_id/performance/certifications" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "shows the dashboard subtitle" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response.body).to include(
          I18n.t("student_performance.certifications.index.subtitle")
        )
      end

      # Mid-term the screen has to say why it proposes nothing, or it reads as
      # broken rather than as "too early".
      context "while the list of assignments is open" do
        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture, min_percentage: 50)
        end

        let(:hint) do
          I18n.t("student_performance.certifications.index.assignments_incomplete",
                 tab: I18n.t("assessment.tabs.assignments"))
        end

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: student,
                            percentage_materialized: 90,
                            points_total_materialized: 90,
                            points_max_materialized: 100)
          lecture.update!(assignments_complete: false)
        end

        it "says why nothing is proposed and what to do" do
          get lecture_student_performance_certifications_path(lecture)

          expect(response.body).to include(CGI.escapeHTML(hint))
        end

        it "leaves the sweep visible but refuses to run it" do
          get lecture_student_performance_certifications_path(lecture)

          expect(response.body).to include(
            I18n.t("student_performance.certifications.index.bulk_accept")
          )
          expect(response.body).to include("disabled")
        end

        # The banner carries the same words, so the whole page is no evidence:
        # the reason has to stand on the student's own row.
        it "defers a student who clears the threshold today" do
          FactoryBot.create(:student_performance_certification,
                            lecture: lecture, user: student)

          get lecture_student_performance_certifications_path(lecture)

          row = Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
            tr.text.include?(student.tutorial_name)
          end

          expect(row.text).to include(
            I18n.t("student_performance.evaluator.deferral.assignments_incomplete")
          )
        end

        # Searching the whole page would find the box's wording, so the
        # assertion is scoped to the row.
        it "does not repeat the banner on a decided row" do
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture, user: student)

          get lecture_student_performance_certifications_path(lecture)

          row = Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
            tr.text.include?(student.tutorial_name)
          end

          expect(row.text).to include(
            I18n.t("student_performance.certifications.rule_today.inconclusive")
          )
          expect(row.text).not_to include(
            I18n.t("student_performance.evaluator.deferral.assignments_incomplete")
          )
        end
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
          expect(response.body).to include(CGI.escapeHTML(user_a.tutorial_name))
          expect(response.body).to include(CGI.escapeHTML(user_b.tutorial_name))
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
            expect(response.body).to include(CGI.escapeHTML(user_a.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_b.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_c.tutorial_name))
          end

          it "filters by failed status" do
            get lecture_student_performance_certifications_path(
              lecture, status: "failed"
            )
            expect(response.body).not_to include(CGI.escapeHTML(user_a.tutorial_name))
            expect(response.body).to include(CGI.escapeHTML(user_b.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_c.tutorial_name))
          end

          it "filters by uncertified status" do
            uncertified_user = FactoryBot.create(:confirmed_user)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: uncertified_user)
            get lecture_student_performance_certifications_path(
              lecture, status: "uncertified"
            )
            expect(response.body).to include(CGI.escapeHTML(uncertified_user.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_a.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_b.tutorial_name))
            expect(response.body).to include(CGI.escapeHTML(user_c.tutorial_name))
          end

          # user_a is certified as passed but would fail today; user_b is
          # certified as failed and would fail today as well.
          it "filters by flagged status" do
            FactoryBot.create(:student_performance_rule, :active,
                              :with_percentage,
                              lecture: lecture, min_percentage: 50)
            # rubocop:disable Rails/SkipsModelValidations
            StudentPerformance::Record.where(lecture: lecture)
                                      .update_all(percentage_materialized: 40,
                                                  points_total_materialized: 40,
                                                  points_max_materialized: 100)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(
              lecture, status: "flagged"
            )
            expect(response.body).to include(CGI.escapeHTML(user_a.tutorial_name))
            expect(response.body).not_to include(CGI.escapeHTML(user_b.tutorial_name))
          end

          it "sends the filter's old name to its new one" do
            get lecture_student_performance_certifications_path(
              lecture, status: "stale"
            )

            expect(response).to redirect_to(
              lecture_student_performance_certifications_path(
                lecture, status: "flagged"
              )
            )
          end
        end

        context "with the attention banners" do
          let!(:rule) do
            FactoryBot.create(:student_performance_rule, :active,
                              :with_percentage,
                              lecture: lecture,
                              min_percentage: 50)
          end

          def record_for(user, percentage)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user,
                              percentage_materialized: percentage,
                              points_total_materialized: percentage,
                              points_max_materialized: 100)
          end

          it "offers to reconcile when the rule contradicts a computed decision" do
            record_for(user_a, 40)

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(
              I18n.t("student_performance.certifications.index.disagreeing_warning",
                     count: 1)
            )
            expect(response.body).to include(
              I18n.t("student_performance.certifications.index.reevaluate")
            )
          end

          it "leaves a computed decision the rule still agrees with alone" do
            record_for(user_a, 60)
            cert_passed.update!(rule: rule)
            # rubocop:disable Rails/SkipsModelValidations
            cert_passed.update_columns(certified_at: 2.hours.ago)
            rule.update_columns(updated_at: 1.hour.ago)
            # rubocop:enable Rails/SkipsModelValidations

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).not_to include(
              I18n.t("student_performance.certifications.index.reevaluate")
            )
            row = Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
              tr.text.include?(user_a.tutorial_name)
            end

            expect(row.css("td")[-3].text.strip).to be_empty
          end

          it "does not call a deferred row a contradiction" do
            record_for(user_c, 40)

            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).not_to include(
              I18n.t("student_performance.certifications.index.disagreeing_warning",
                     count: 1)
            )
            expect(response.body).to include(
              I18n.t("student_performance.certifications.columns.proposed")
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
                ".stale_manual_warning",
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
              I18n.t("student_performance.certifications.index.reevaluate")
            )
          end
        end
      end

      # The one screen staff work through student by student, so it has to be
      # possible to go to one student and to get through a full lecture.
      context "with a search" do
        # Spelled out rather than drawn from Faker: what a search finds has to
        # be a matter of the search term alone.
        def named(name, email)
          FactoryBot.create(:confirmed_user, name: name,
                                             name_in_tutorials: name,
                                             email: email)
        end

        def listed_names
          Nokogiri::HTML(response.body).css("tbody tr td:first-child")
                  .map { |td| td.text.strip }
        end

        let(:ada) { named("Ada Lovelace", "ada@algol.test") }
        let(:grace) { named("Grace Hopper", "grace@cobol.test") }

        before do
          [ada, grace].each do |user|
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user)
          end
        end

        it "narrows the table to the searched name" do
          get lecture_student_performance_certifications_path(lecture, q: "hopper")

          expect(listed_names).to eq(["Grace Hopper"])
        end

        it "searches within the status that is filtered for" do
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture, user: ada)

          get lecture_student_performance_certifications_path(
            lecture, status: "passed", q: "hopper"
          )

          expect(listed_names).to be_empty
          expect(response.body).to include(
            I18n.t("student_performance.lists.no_match")
          )
        end

        # A decision is made from a list that may be searched, filtered and on
        # its third page; landing back on the unfiltered first page loses the
        # student who was being worked through.
        it "comes back to the list a decision was made from" do
          get lecture_student_performance_certifications_path(
            lecture, q: "hopper", status: "uncertified"
          )

          form = Nokogiri::HTML(response.body)
                         .css("#performance-certifications-frame tbody form")
                         .first
          return_to = form.at_css("input[name='return_to']")["value"]

          expect(return_to).to include("q=hopper")
          expect(return_to).to include("status=uncertified")
        end

        it "carries the search into the status filter's own links" do
          get lecture_student_performance_certifications_path(lecture, q: "hopper")

          pills = Nokogiri::HTML(response.body)
                          .css("#performance-certifications-frame .nav-pills a")
                          .pluck("href")

          expect(pills).to all(include("q=hopper"))
        end
      end

      context "with more students than fit on a page" do
        before do
          21.times do
            FactoryBot.create(:student_performance_record, lecture: lecture)
          end
        end

        it "cuts the list into pages" do
          get lecture_student_performance_certifications_path(lecture)

          pagy = controller.instance_variable_get(:@pagy)

          expect(pagy.count).to eq(21)
          expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(20)
        end

        it "serves the rest on the second page" do
          get lecture_student_performance_certifications_path(lecture, page: 2)

          expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(1)
        end

        # The records of a lecture are written in one go, so their timestamps
        # are the same, and an order that cannot tell two rows apart hands them
        # out in any order it likes - once on one page, once on the next, and
        # somebody else on neither. Measured before the tie-breaker: 100 rows,
        # 99 of them different students.
        it "shows every student exactly once across the pages" do
          stamp = Time.zone.now
          100.times do |i|
            user = FactoryBot.create(:confirmed_user,
                                     name: "Student #{i.to_s.rjust(3, "0")}",
                                     name_in_tutorials: "Student #{i.to_s.rjust(3, "0")}")
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user,
                              created_at: stamp, updated_at: stamp)
          end

          seen = (1..7).flat_map do |page|
            get(lecture_student_performance_certifications_path(lecture, page: page))
            Nokogiri::HTML(response.body)
                    .css("#performance-certifications-frame tbody tr td:first-child")
                    .map { |cell| cell.text.strip }
          end

          expect(seen.uniq.size).to eq(seen.size)
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

        it "shows the edit rule button" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.rules.show.edit_button")
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

      context "with a pending certification" do
        let(:achievement) { FactoryBot.create(:achievement, lecture: lecture) }
        let(:undecided_user) { FactoryBot.create(:confirmed_user) }
        let(:rule_today) do
          I18n.t("student_performance.certifications.columns.rule_today")
        end
        # The two open points reasons say how many sheets they are about, so a
        # test that names one has to say how many too.
        def deferral(reason, count: nil)
          return I18n.t("student_performance.evaluator.deferral.#{reason}") unless count

          I18n.t("student_performance.evaluator.deferral.#{reason}", count: count)
        end

        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: undecided_user,
                            percentage_materialized: 80,
                            points_total_materialized: 80,
                            points_max_materialized: 100,
                            achievements_ungraded_ids: [achievement.id])
          FactoryBot.create(:student_performance_certification,
                            lecture: lecture, user: undecided_user)
        end

        context "when the rule cannot decide either" do
          before do
            FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: achievement)
          end

          it "does not claim the rule says something else" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).not_to include(rule_today)
          end

          it "names the unmarked achievement as the reason" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(deferral(:achievements_ungraded))
          end
        end

        context "when there are no points to measure" do
          let(:exempt_user) { FactoryBot.create(:confirmed_user) }

          before do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: exempt_user,
                              percentage_materialized: 0,
                              points_total_materialized: 0,
                              points_max_materialized: 0)
            FactoryBot.create(:student_performance_certification,
                              lecture: lecture, user: exempt_user)
          end

          it "says so instead of blaming missing input" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).to include(deferral(:points_not_measurable))
            expect(response.body)
              .not_to include(deferral(:points_pending, count: 0))
          end
        end

        context "when the marking still outstanding could carry the student" do
          let(:awaited_user) { FactoryBot.create(:confirmed_user) }

          # The hand-in behind the materialized figure is created too: the page
          # counts the sheets that are waiting, and the record sums what they
          # are worth. In real data both come from the same participations.
          before do
            waiting = FactoryBot.create(:assignment, :expired, lecture: lecture)
            FactoryBot.create(:assessment_task,
                              assessment: waiting.assessment, max_points: 40)
            FactoryBot.create(:assessment_participation,
                              assessment: waiting.assessment, user: awaited_user,
                              submitted_at: 1.day.ago)
            # The new sheet reopened the list; the lecturer has closed it again.
            lecture.update!(assignments_complete: true)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: awaited_user,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100,
                              points_max_pending_materialized: 40)
            FactoryBot.create(:student_performance_certification,
                              lecture: lecture, user: awaited_user)
          end

          it "points at the marking rather than at the student" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body)
              .to include(deferral(:points_pending, count: 1))
          end
        end

        # Mid-term the sheets to come outnumber the ones handed out; refusing
        # a student for work nobody has set yet is the worse mistake.
        context "when the term still has sheets to come" do
          let(:early_user) { FactoryBot.create(:confirmed_user) }

          before do
            assignment = FactoryBot.create(:assignment, lecture: lecture,
                                                        deadline: 3.days.from_now)
            FactoryBot.create(:assessment_task,
                              assessment: assignment.assessment,
                              max_points: 40)
            # The new sheet reopened the list; here the lecturer has said that
            # this one is the last.
            lecture.update!(assignments_complete: true)
            FactoryBot.create(:student_performance_record,
                              lecture: lecture,
                              user: early_user,
                              percentage_materialized: 30,
                              points_total_materialized: 30,
                              points_max_materialized: 100,
                              points_max_pending_materialized: 0)
            FactoryBot.create(:student_performance_certification,
                              lecture: lecture, user: early_user)
          end

          it "names the sheets to come rather than refusing the student" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body)
              .to include(deferral(:points_not_due, count: 1))
            expect(response.body)
              .not_to include(deferral(:points_pending, count: 0))
          end
        end

        context "when the rule would let the student through" do
          it "shows the proposal rather than a contradiction" do
            get lecture_student_performance_certifications_path(lecture)
            expect(response.body).not_to include(rule_today)
            expect(response.body).to include(
              I18n.t("student_performance.certifications.columns.proposed")
            )
            expect(response.body).to include(
              I18n.t("student_performance.evaluator.status.passed")
            )
          end

          it "offers no reason where there is nothing to explain" do
            get lecture_student_performance_certifications_path(lecture)
            StudentPerformance::Evaluator::DEFERRAL_REASONS.each do |reason|
              expect(response.body)
                .not_to include(deferral(reason, count: 0))
            end
          end
        end
      end

      context "with a decided certification the rule would now defer" do
        let(:achievement) { FactoryBot.create(:achievement, lecture: lecture) }
        let(:decided_user) { FactoryBot.create(:confirmed_user) }

        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        before do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: achievement)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: decided_user,
                            percentage_materialized: 80,
                            points_total_materialized: 80,
                            points_max_materialized: 100,
                            achievements_ungraded_ids: [achievement.id])
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture, user: decided_user)
        end

        it "says the rule disagrees" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.columns.rule_today")
          )
          expect(response.body).to include(
            I18n.t("student_performance.certifications.rule_today.inconclusive")
          )
        end

        it "names why the rule would defer now" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.deferral.achievements_ungraded")
          )
        end

        it "keeps the note column for the note" do
          StudentPerformance::Certification
            .find_by(lecture: lecture, user: decided_user)
            .update!(note: "Sick note on file")

          get lecture_student_performance_certifications_path(lecture)
          row = Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
            tr.text.include?(decided_user.tutorial_name)
          end

          expect(row.css("td")[-2].text.strip).to eq("Sick note on file")
        end
      end

      context "with a decided certification the rule would now fail" do
        let(:decided_user) { FactoryBot.create(:confirmed_user) }

        let!(:rule) do
          FactoryBot.create(:student_performance_rule, :active,
                            :with_percentage,
                            lecture: lecture,
                            min_percentage: 50)
        end

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture,
                            user: decided_user,
                            percentage_materialized: 40,
                            points_total_materialized: 40,
                            points_max_materialized: 100)
          FactoryBot.create(:student_performance_certification, :passed,
                            lecture: lecture, user: decided_user)
        end

        it "names the criterion the student misses" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.rule_today.failed")
          )
          expect(response.body).to include(
            I18n.t("student_performance.evaluator.missed.points")
          )
        end

        # Nothing is open for this student, so the plain sentence is the right
        # one; the stronger one belongs to a student who still has marking
        # outstanding that would not be enough either.
        it "does not claim more than that the threshold was not reached" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).not_to include(
            I18n.t("student_performance.evaluator.missed.points_out_of_reach")
          )
        end

        it "keeps the decision as it is" do
          get lecture_student_performance_certifications_path(lecture)
          row = Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
            tr.text.include?(decided_user.tutorial_name)
          end

          expect(row.text).to include(
            I18n.t("student_performance.certifications.status.passed")
          )
        end

        it "offers the reset on the row" do
          get lecture_student_performance_certifications_path(lecture)
          expect(response.body).to include(
            I18n.t("student_performance.certifications.index.reset")
          )
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

      it "creates a manual certification without an active rule" do
        rule.update!(active: false)
        expect do
          post(lecture_student_performance_certifications_path(lecture),
               params: { certification: {
                 user_id: target_user.id, status: "passed"
               } })
        end.to change(StudentPerformance::Certification, :count).by(1)
        cert = StudentPerformance::Certification.find_by(
          user: target_user, lecture: lecture
        )
        expect(cert.status).to eq("passed")
        expect(cert.source).to eq("manual")
        expect(cert.certified_by).to eq(editor)
        expect(cert.rule).to be_nil
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
        FactoryBot.create(:student_performance_certification, :passed, :manual,
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

      # Reachable past a disabled button, and it would write nothing but
      # "deferred" over every decision already taken.
      it "refuses to sweep while the list of assignments is open" do
        lecture.update!(assignments_complete: false)

        expect do
          post(bulk_accept_lecture_student_performance_certifications_path(
                 lecture
               ))
        end.not_to change(StudentPerformance::Certification, :count)

        expect(flash[:alert]).to eq(
          I18n.t("student_performance.certifications.index.assignments_incomplete",
                 tab: I18n.t("assessment.tabs.assignments"))
        )
      end

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

      # The button is hidden without a rule, so this guard is only ever met by a
      # request that did not come from the page.
      it "refuses to accept proposals when no rule proposes anything" do
        rule.update!(active: false)

        expect do
          post(bulk_accept_lecture_student_performance_certifications_path(
                 lecture
               ))
        end.not_to change(StudentPerformance::Certification, :count)

        expect(flash[:alert]).to eq(I18n.t("student_performance.evaluator.no_rule"))
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

      context "when proposal is inconclusive (input missing)" do
        let(:achievement) do
          FactoryBot.create(:achievement, lecture: lecture)
        end
        let(:undecided_user) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: achievement)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: undecided_user,
                            percentage_materialized: 80,
                            points_total_materialized: 80,
                            points_max_materialized: 100,
                            achievements_ungraded_ids: [achievement.id])
        end

        it "persists a pending computed certification (no human verdict)" do
          post bulk_accept_lecture_student_performance_certifications_path(
            lecture
          )
          cert = StudentPerformance::Certification.find_by(
            user: undecided_user, lecture: lecture
          )
          expect(cert.status).to eq("pending")
          expect(cert.source).to eq("computed")
          expect(cert.certified_by).to be_nil
          expect(cert.certified_at).to be_within(5.seconds).of(Time.current)
          expect(cert.rule).to eq(rule)
        end

        it "mentions the inconclusive count in the flash" do
          post bulk_accept_lecture_student_performance_certifications_path(
            lecture
          )
          follow_redirect!
          expect(response.body).to include(
            I18n.t(
              "student_performance.certifications.flash.bulk_inconclusive",
              count: 1
            )
          )
        end
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

      it "rewrites the decisions the rule contradicts and leaves the rest" do
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
        expect(cert_a.certified_at).to be_within(5.seconds).of(4.hours.ago)
        expect(cert_b.status).to eq("failed")
        expect(cert_b.certified_at).to be_within(5.seconds).of(Time.current)
      end

      it "leaves a deferred row to the accept sweep" do
        cert = FactoryBot.create(
          :student_performance_certification, :pending,
          lecture: lecture, user: user_b, rule: rule
        )

        post bulk_reevaluate_lecture_student_performance_certifications_path(
          lecture
        )

        expect(cert.reload.status).to eq("pending")
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
          lecture: lecture, user: user_b, rule: rule,
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

      context "when re-evaluation now yields inconclusive" do
        let(:achievement) do
          FactoryBot.create(:achievement, lecture: lecture)
        end

        let!(:cert_a) do
          FactoryBot.create(
            :student_performance_certification, :passed,
            lecture: lecture, user: user_a, rule: rule,
            certified_at: 4.hours.ago
          )
        end

        before do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: achievement)
          record = StudentPerformance::Record.find_by(
            lecture: lecture, user: user_a
          )
          # rubocop:disable Rails/SkipsModelValidations
          record.update_columns(
            achievements_ungraded_ids: [achievement.id],
            computed_at: 1.hour.ago
          )
          # rubocop:enable Rails/SkipsModelValidations
        end

        it "resets the certification to pending+computed" do
          post bulk_reevaluate_lecture_student_performance_certifications_path(
            lecture
          )
          cert_a.reload
          expect(cert_a.status).to eq("pending")
          expect(cert_a.source).to eq("computed")
          expect(cert_a.certified_by).to be_nil
          expect(cert_a.certified_at).to be_within(5.seconds).of(Time.current)
        end

        it "removes the cert from the stale set" do
          post bulk_reevaluate_lecture_student_performance_certifications_path(
            lecture
          )
          expect(StudentPerformance::Certification.stale).not_to include(
            cert_a.reload
          )
        end

        it "mentions the inconclusive count in the flash" do
          post bulk_reevaluate_lecture_student_performance_certifications_path(
            lecture
          )
          follow_redirect!
          expect(response.body).to include(
            I18n.t(
              "student_performance.certifications.flash" \
              ".reevaluated_inconclusive",
              count: 1
            )
          )
        end
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

  describe "POST /lectures/:lecture_id/performance/certifications/bulk_confirm_manual" do
    let!(:rule) do
      FactoryBot.create(:student_performance_rule, :active,
                        :with_percentage,
                        lecture: lecture,
                        min_percentage: 50)
    end

    let(:user_a) { FactoryBot.create(:confirmed_user) }
    let(:user_b) { FactoryBot.create(:confirmed_user) }
    let(:user_c) { FactoryBot.create(:confirmed_user) }

    before do
      [user_a, user_b, user_c].each do |u|
        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: u,
                          percentage_materialized: 60,
                          points_total_materialized: 60,
                          points_max_materialized: 100)
      end
    end

    context "as an editor" do
      before { sign_in editor }

      it "confirms stale manual certifications" do
        stale_manual = FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: user_a,
          certified_by: editor,
          certified_at: 1.day.ago
        )
        rule.update_column(:updated_at, Time.current) # rubocop:disable Rails/SkipsModelValidations

        post bulk_confirm_manual_lecture_student_performance_certifications_path(
          lecture
        )
        stale_manual.reload
        expect(stale_manual.certified_at).to be > 1.minute.ago
        expect(stale_manual.status).to eq("passed")
        expect(stale_manual.source).to eq("manual")
      end

      it "does not touch non-stale manual certifications" do
        fresh_manual = FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: user_b,
          certified_by: editor,
          certified_at: Time.current
        )
        original_time = fresh_manual.certified_at

        post bulk_confirm_manual_lecture_student_performance_certifications_path(
          lecture
        )
        fresh_manual.reload
        expect(fresh_manual.certified_at).to be_within(1.second)
          .of(original_time)
      end

      it "does not touch computed certifications" do
        stale_computed = FactoryBot.create(
          :student_performance_certification, :passed,
          lecture: lecture, user: user_c,
          source: :computed,
          certified_by: editor,
          certified_at: 1.day.ago
        )
        rule.update_column(:updated_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
        original_time = stale_computed.certified_at

        post bulk_confirm_manual_lecture_student_performance_certifications_path(
          lecture
        )
        stale_computed.reload
        expect(stale_computed.certified_at).to be_within(1.second)
          .of(original_time)
      end

      it "redirects with flash count" do
        FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: user_a,
          certified_by: editor,
          certified_at: 1.day.ago
        )
        rule.update_column(:updated_at, Time.current) # rubocop:disable Rails/SkipsModelValidations

        post bulk_confirm_manual_lecture_student_performance_certifications_path(
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
        post bulk_confirm_manual_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(root_url)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        post bulk_confirm_manual_lecture_student_performance_certifications_path(
          lecture
        )
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
  describe "DELETE /lectures/:lecture_id/performance/certifications/:id" do
    let(:target_user) { FactoryBot.create(:confirmed_user) }

    let!(:cert) do
      FactoryBot.create(:student_performance_certification, :passed,
                        lecture: lecture, user: target_user)
    end

    before do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: target_user)
    end

    context "as an editor" do
      before { sign_in editor }

      it "drops the decision so the proposal shows again" do
        delete lecture_student_performance_certification_path(lecture, cert)

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        expect(StudentPerformance::Certification.exists?(cert.id)).to be(false)
      end

      it "drops a manual decision too, one at a time" do
        manual = FactoryBot.create(
          :student_performance_certification, :passed, :manual,
          lecture: lecture, user: FactoryBot.create(:confirmed_user)
        )

        delete lecture_student_performance_certification_path(lecture, manual)

        expect(StudentPerformance::Certification.exists?(manual.id)).to be(false)
      end

      it "says so" do
        delete lecture_student_performance_certification_path(lecture, cert)
        follow_redirect!

        expect(response.body).to include(
          I18n.t("student_performance.certifications.flash.reset_one")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        delete lecture_student_performance_certification_path(lecture, cert)

        expect(response).to redirect_to(root_url)
        expect(StudentPerformance::Certification.exists?(cert.id)).to be(true)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        delete lecture_student_performance_certification_path(lecture, cert)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/certifications/bulk_reset" do
    let!(:computed_passed) do
      FactoryBot.create(:student_performance_certification, :passed,
                        lecture: lecture)
    end

    let!(:computed_failed) do
      FactoryBot.create(:student_performance_certification, :failed,
                        lecture: lecture)
    end

    let!(:computed_pending) do
      FactoryBot.create(:student_performance_certification, :pending,
                        lecture: lecture)
    end

    let!(:manual) do
      FactoryBot.create(:student_performance_certification, :failed, :manual,
                        lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      it "drops everything computed and keeps the manual ones" do
        post bulk_reset_lecture_student_performance_certifications_path(lecture)

        expect(response).to redirect_to(
          lecture_student_performance_certifications_path(lecture)
        )
        remaining = StudentPerformance::Certification.where(lecture: lecture)
        expect(remaining).to contain_exactly(manual)
      end

      it "leaves other lectures alone" do
        elsewhere = FactoryBot.create(:student_performance_certification,
                                      :passed)

        post bulk_reset_lecture_student_performance_certifications_path(lecture)

        expect(StudentPerformance::Certification.exists?(elsewhere.id)).to be(true)
      end

      it "counts the decisions it dropped" do
        post bulk_reset_lecture_student_performance_certifications_path(lecture)
        follow_redirect!

        expect(response.body).to include(
          I18n.t("student_performance.certifications.flash.reset", count: 2)
        )
      end

      it "offers the sweep only while there is something to reset" do
        get lecture_student_performance_certifications_path(lecture)
        expect(response.body).to include(
          I18n.t("student_performance.certifications.index.bulk_reset",
                 count: 2)
        )

        post bulk_reset_lecture_student_performance_certifications_path(lecture)
        get lecture_student_performance_certifications_path(lecture)
        expect(response.body).not_to include(
          bulk_reset_lecture_student_performance_certifications_path(lecture)
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root" do
        post bulk_reset_lecture_student_performance_certifications_path(lecture)

        expect(response).to redirect_to(root_url)
        expect(StudentPerformance::Certification.where(lecture: lecture).count)
          .to eq(4)
      end
    end

    context "as an unauthenticated user" do
      it "redirects to sign in" do
        post bulk_reset_lecture_student_performance_certifications_path(lecture)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
