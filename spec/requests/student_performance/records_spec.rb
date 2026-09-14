require "rails_helper"

RSpec.describe("StudentPerformance::Records", type: :request) do
  let(:lecture) { FactoryBot.create(:lecture, locale: I18n.default_locale) }
  let(:editor) { FactoryBot.create(:confirmed_user) }
  let(:student) { FactoryBot.create(:confirmed_user) }

  before do
    FactoryBot.create(:editable_user_join, user: editor, editable: lecture)
    editor.reload
    lecture.reload
  end
  describe "GET /lectures/:lecture_id/performance/records" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to have_http_status(:success)
      end

      it "includes records for the lecture" do
        user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: user)
        get lecture_student_performance_records_path(lecture)
        expect(response.body).to include(CGI.escapeHTML(user.tutorial_name))
      end

      it "does not include records from other lectures" do
        other_user = FactoryBot.create(:confirmed_user)
        other_lecture = FactoryBot.create(:lecture)
        FactoryBot.create(:student_performance_record,
                          lecture: other_lecture, user: other_user)
        get lecture_student_performance_records_path(lecture)
        expect(response.body).not_to include(CGI.escapeHTML(other_user.tutorial_name))
      end

      it "renders a dash when percentage is unavailable" do
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          percentage_materialized: nil,
                          points_total_materialized: 0,
                          points_max_materialized: 0)

        get lecture_student_performance_records_path(lecture)

        expect(response.body).to include(
          I18n.t("student_performance.records.percentage_unavailable")
        )
        expect(response.body).not_to include(">0%</span>")
      end

      # In a term where every sheet is over the deadline the difference is
      # invisible; the state this covers is the middle of a running term.
      context "with a sheet that is not due yet" do
        let(:member) { FactoryBot.create(:confirmed_user) }

        def cells_for(user)
          Nokogiri::HTML(response.body).css("tbody tr").find do |tr|
            tr.text.include?(user.tutorial_name)
          end.css("td")
        end

        def sheet(deadline:, points:)
          assignment = FactoryBot.create(:assignment, lecture: lecture,
                                                      deadline: 1.year.from_now)
          # rubocop:disable Rails/SkipsModelValidations
          assignment.update_column(:deadline, deadline)
          # rubocop:enable Rails/SkipsModelValidations
          FactoryBot.create(:assessment_task,
                            assessment: assignment.assessment,
                            max_points: points)
          assignment.assessment.reload
        end

        # A sheet that counts towards none of the figures here has no column;
        # a column of dashes would be the exception to the rule the table sets.
        it "gives a sheet that is not due yet no column" do
          due = sheet(deadline: 2.days.ago, points: 20)
          coming = sheet(deadline: 3.days.from_now, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)

          get lecture_student_performance_records_path(lecture)

          titles = Nokogiri::HTML(response.body)
                           .css("thead tr")[1].css("th")
                           .filter_map { |th| th["title"] }

          expect(titles).to include(due.title)
          expect(titles).not_to include(coming.title)
        end

        it "says in the heading how many sheets it left out" do
          sheet(deadline: 2.days.ago, points: 20)
          sheet(deadline: 3.days.from_now, points: 16)
          sheet(deadline: 4.days.from_now, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)

          get lecture_student_performance_records_path(lecture)

          heading = Nokogiri::HTML(response.body).css("thead tr").first
                            .css("th").find do |th|
            th.text.include?(
              I18n.t("student_performance.records.columns.assignments")
            )
          end

          expect(heading.text).to include(
            I18n.t("student_performance.records.columns.not_due_count", count: 2)
          )
        end

        # Nobody may mark before the grace period is over, so an early hand-in
        # is waiting for the deadline rather than for a tutor, and no hourglass
        # claims a backlog on that sheet.
        it "flags a marking backlog only where marking could have happened" do
          due = sheet(deadline: 2.days.ago, points: 20)
          coming = sheet(deadline: 3.days.from_now, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          [due, coming].each do |assessment|
            FactoryBot.create(:assessment_participation, :submitted,
                              assessment: assessment, user: member)
          end

          get lecture_student_performance_records_path(lecture)

          head = Nokogiri::HTML(response.body).css("thead")

          header = head.css("th").find { |th| th["title"] == due.title }

          expect(head.css(".bi-hourglass-split").size).to eq(1)
          expect(header.at_css(".bi-hourglass-split")["aria-label"]).to eq(
            I18n.t("student_performance.records.index.awaiting_marking", count: 1)
          )
        end

        # The complaint this basis answers: a deadline passes, the tutor has not
        # got to it, and a flawless student drops to half her figure overnight
        # for something she did not do.
        it "does not let a tutor's backlog read as a student's shortfall" do
          sheet(deadline: 3.days.ago, points: 20)
          waiting = sheet(deadline: 2.days.ago, points: 20)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          FactoryBot.create(:assessment_participation, assessment: waiting,
                                                       user: member,
                                                       submitted_at: 1.day.ago)
          # rubocop:disable Rails/SkipsModelValidations
          StudentPerformance::Record
            .where(lecture: lecture, user: member)
            .update_all(points_total_materialized: 20,
                        points_max_materialized: 40)
          # rubocop:enable Rails/SkipsModelValidations

          get lecture_student_performance_records_path(lecture)

          helpers = ApplicationController.helpers
          expect(response.body)
            .to include(helpers.number_to_percentage(100, precision: 0))
          expect(response.body)
            .not_to include(helpers.number_to_percentage(50, precision: 0))
        end

        it "measures the percentage against the sheets due so far" do
          sheet(deadline: 2.days.ago, points: 20)
          sheet(deadline: 3.days.from_now, points: 20)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          # rubocop:disable Rails/SkipsModelValidations
          StudentPerformance::Record
            .where(lecture: lecture, user: member)
            .update_all(points_total_materialized: 20,
                        points_max_materialized: 40,
                        percentage_materialized: 50)
          # rubocop:enable Rails/SkipsModelValidations

          get lecture_student_performance_records_path(lecture)

          helpers = ApplicationController.helpers
          expect(response.body)
            .to include(helpers.number_to_percentage(100, precision: 0))
          expect(response.body)
            .not_to include(helpers.number_to_percentage(50, precision: 0))
        end

        # One heading over all three figures, and it has to be readable without
        # opening anything — the sentence behind the icon only elaborates.
        it "names what the figures are measured against, once" do
          sheet(deadline: 2.days.ago, points: 20)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)

          get lecture_student_performance_records_path(lecture)

          group, columns = Nokogiri::HTML(response.body).css("thead tr")
          heading = group.css("th").find do |th|
            th.text.include?(
              I18n.t("student_performance.records.columns.due_so_far")
            )
          end

          expect(heading["colspan"]).to eq("3")
          expect(heading.at_css("[data-bs-content]")["data-bs-content"]).to eq(
            I18n.t("student_performance.records.columns.due_so_far_hint")
          )
          expect(columns.css("th").first.text)
            .to include(I18n.t("student_performance.records.columns.points"))
          expect(columns.css("th")[1].text)
            .to include(I18n.t("student_performance.records.columns.maximum"))
          expect(columns.css("th")[2].text)
            .to include(I18n.t("student_performance.records.columns.percentage"))
        end

        # The maximum differs from student to student - by what she was let off
        # and by what her tutor has not marked yet - so it cannot stand once in
        # the heading. It is a column, and every row fills it.
        it "gives each student her own maximum, in its own column" do
          excused = sheet(deadline: 3.days.ago, points: 20)
          sheet(deadline: 2.days.ago, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          FactoryBot.create(:assessment_participation, :exempt,
                            assessment: excused, user: member)
          other = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: other)

          get lecture_student_performance_records_path(lecture)

          expect(cells_for(member)[2].text.strip).to eq("16")
          expect(cells_for(other)[2].text.strip).to eq("36")
        end

        # Each figure keeps its own column, so none of them carries a fraction.
        it "keeps the points column to one figure" do
          excused = sheet(deadline: 3.days.ago, points: 20)
          sheet(deadline: 2.days.ago, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          FactoryBot.create(:assessment_participation, :exempt,
                            assessment: excused, user: member)

          get lecture_student_performance_records_path(lecture)

          expect(cells_for(member)[1].text).not_to include("/")
        end

        # With the maximum in the row, a footnote by the name would say the
        # same thing twice - and it could only name one of the two reasons.
        it "says nothing next to the name of an excused student" do
          excused = sheet(deadline: 3.days.ago, points: 20)
          sheet(deadline: 2.days.ago, points: 16)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          FactoryBot.create(:assessment_participation, :exempt,
                            assessment: excused, user: member)

          get lecture_student_performance_records_path(lecture)

          expect(cells_for(member).first.at_css("[data-bs-content]")).to be_nil
        end
      end

      context "with achievements" do
        it "renders achievement columns when achievements exist" do
          user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership,
                            lecture: lecture, user: user)
          achievement = FactoryBot.create(:achievement, :boolean,
                                          lecture: lecture)
          # rubocop:disable Rails/SkipsModelValidations
          StudentPerformance::Record
            .where(lecture: lecture, user: user)
            .update_all(achievements_met_ids: [achievement.id])
          # rubocop:enable Rails/SkipsModelValidations

          get lecture_student_performance_records_path(lecture)
          expect(response.body).to include(achievement.title)
          expect(response.body).to include(%(class="bi bi-check-circle text-success"))
          expect(response.body).to include(
            %(aria-label="#{I18n.t("student_performance.records.columns.achievement_met")}")
          )
        end

        it "renders not-met icon for unmet achievements" do
          user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership,
                            lecture: lecture, user: user)
          achievement = FactoryBot.create(:achievement, :boolean,
                                          lecture: lecture)
          # rubocop:disable Rails/SkipsModelValidations
          StudentPerformance::Record
            .where(lecture: lecture, user: user)
            .update_all(
              achievements_met_ids: [],
              achievements_ungraded_ids: []
            )
          # rubocop:enable Rails/SkipsModelValidations

          get lecture_student_performance_records_path(lecture)
          expect(response.body).to include(achievement.title)
          expect(response.body).to include(%(class="bi bi-x-circle text-danger"))
          expect(response.body).to include(
            %(aria-label="#{I18n.t("student_performance.records.columns.achievement_not_met")}")
          )
        end

        it "renders an accessible label for ungraded achievements" do
          user = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership,
                            lecture: lecture, user: user)
          achievement = FactoryBot.create(:achievement, :boolean,
                                          lecture: lecture)
          # rubocop:disable Rails/SkipsModelValidations
          StudentPerformance::Record
            .where(lecture: lecture, user: user)
            .update_all(
              achievements_met_ids: [],
              achievements_ungraded_ids: [achievement.id]
            )
          # rubocop:enable Rails/SkipsModelValidations

          get lecture_student_performance_records_path(lecture)
          expect(response.body).to include(achievement.title)
          expect(response.body).to include(%(class="bi bi-question-circle text-amber"))
          expect(response.body).to include(
            %(aria-label="#{I18n.t("student_performance.records.columns.achievement_ungraded")}")
          )
        end
      end

      context "with tutorial filter" do
        let(:tutorial) do
          FactoryBot.create(:tutorial, lecture: lecture)
        end
        let(:member) { FactoryBot.create(:confirmed_user) }
        let(:non_member) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:tutorial_membership,
                            tutorial: tutorial, user: member)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: member)
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: non_member)
        end

        it "filters records by tutorial_id" do
          get lecture_student_performance_records_path(
            lecture, tutorial_id: tutorial.id
          )
          expect(response.body).to include(CGI.escapeHTML(member.tutorial_name))
          expect(response.body).not_to include(CGI.escapeHTML(non_member.tutorial_name))
        end

        it "ignores tutorial_ids from other lectures" do
          other_lecture = FactoryBot.create(:lecture)
          other_tutorial = FactoryBot.create(:tutorial, lecture: other_lecture)
          FactoryBot.create(:tutorial_membership,
                            tutorial: other_tutorial, user: member)

          get lecture_student_performance_records_path(
            lecture, tutorial_id: other_tutorial.id
          )

          expect(response.body).to include(CGI.escapeHTML(member.tutorial_name))
          expect(response.body).to include(CGI.escapeHTML(non_member.tutorial_name))
        end

        # These are the people staff have to chase: enrolled, so they show up at
        # 0 %, but in no tutorial, so they cannot hand anything in.
        it "filters down to people in no tutorial at all" do
          get lecture_student_performance_records_path(lecture, tutorial_id: "none")

          expect(response.body).to include(CGI.escapeHTML(non_member.tutorial_name))
          expect(response.body).not_to include(CGI.escapeHTML(member.tutorial_name))
        end

        it "does not count a tutorial in another lecture as having one" do
          other_lecture = FactoryBot.create(:lecture)
          other_tutorial = FactoryBot.create(:tutorial, lecture: other_lecture)
          FactoryBot.create(:tutorial_membership,
                            tutorial: other_tutorial, user: non_member)

          get lecture_student_performance_records_path(lecture, tutorial_id: "none")

          expect(response.body).to include(CGI.escapeHTML(non_member.tutorial_name))
        end

        it "shows everyone when no filter is given" do
          get lecture_student_performance_records_path(lecture)

          expect(response.body).to include(CGI.escapeHTML(member.tutorial_name))
          expect(response.body).to include(CGI.escapeHTML(non_member.tutorial_name))
        end
      end

      # The two questions staff arrive with: where is this one person, and
      # who is at the bottom.
      context "with a search and a sort order" do
        # Names and addresses are spelled out rather than drawn from Faker:
        # what a search finds has to be a matter of the search term alone.
        def named(name, email)
          FactoryBot.create(:confirmed_user, name: name,
                                             name_in_tutorials: name,
                                             email: email)
        end

        let(:ada) { named("Ada Lovelace", "ada@algol.test") }
        let(:grace) { named("Grace Hopper", "grace@cobol.test") }
        let(:nina) { named("Nina Simone", "nina@jazz.test") }

        def sheet(points)
          assignment = FactoryBot.create(:assignment, lecture: lecture,
                                                      deadline: 1.year.from_now)
          # rubocop:disable Rails/SkipsModelValidations
          assignment.update_column(:deadline, 2.days.ago)
          # rubocop:enable Rails/SkipsModelValidations
          FactoryBot.create(:assessment_task,
                            assessment: assignment.assessment,
                            max_points: points)
          assignment.assessment.reload
        end

        # A hand-in recomputes the record it belongs to, so the figures are
        # written down once everything else is in place.
        def scored(user, points)
          record = lecture.student_performance_records
                          .find_or_initialize_by(user: user)
          record.update!(points_total_materialized: points)
        end

        def listed_names
          Nokogiri::HTML(response.body).css("tbody tr td:first-child")
                  .map { |td| td.text.strip }
        end

        before do
          sheet(10)
          awaiting = sheet(10)
          # Ada's second sheet sits with her tutor, so it is out of her base:
          # she is measured against 10 points where the others face 20.
          FactoryBot.create(:assessment_participation, :submitted,
                            assessment: awaiting, user: ada)
          scored(ada, 8)
          scored(grace, 20)
          scored(nina, 5)
        end

        it "narrows the table to the searched name" do
          get lecture_student_performance_records_path(lecture, q: "hopper")

          expect(listed_names).to eq(["Grace Hopper"])
        end

        # The tutorial filter has its own examples above; what this one is
        # about is that the search narrows what the filter left standing.
        it "searches within the tutorial that is filtered for" do
          tutorial = FactoryBot.create(:tutorial, lecture: lecture)
          [grace, nina].each do |user|
            FactoryBot.create(:tutorial_membership, tutorial: tutorial,
                                                    user: user)
          end

          get lecture_student_performance_records_path(
            lecture, tutorial_id: tutorial.id, q: "simone"
          )

          expect(listed_names).to eq(["Nina Simone"])
        end

        it "says so when nobody matches" do
          get lecture_student_performance_records_path(lecture, q: "Turing")

          expect(response.body).to include(
            I18n.t("student_performance.lists.no_match")
          )
        end

        it "orders by points, largest first" do
          get lecture_student_performance_records_path(
            lecture, sort: "points", dir: "desc"
          )

          expect(listed_names).to eq(["Grace Hopper", "Ada Lovelace",
                                      "Nina Simone"])
        end

        # Grace and Nina face the same 20 points; between the two the table
        # falls back on the order it would have had anyway.
        it "orders by the maximum, largest first" do
          get lecture_student_performance_records_path(
            lecture, sort: "maximum", dir: "desc"
          )

          expect(listed_names).to eq(["Grace Hopper", "Nina Simone",
                                      "Ada Lovelace"])
        end

        it "orders by percentage, smallest first" do
          get lecture_student_performance_records_path(
            lecture, sort: "percentage", dir: "asc"
          )

          expect(listed_names).to eq(["Nina Simone", "Ada Lovelace",
                                      "Grace Hopper"])
        end

        it "keeps the search when a column is sorted" do
          get lecture_student_performance_records_path(
            lecture, q: "ac", sort: "points", dir: "desc"
          )

          expect(listed_names).to eq(["Grace Hopper", "Ada Lovelace"])
        end

        # Clicking the column that is already sorted is how the order is turned
        # around, so its header has to offer the other direction.
        it "offers the opposite direction on the column it sorted by" do
          get lecture_student_performance_records_path(
            lecture, sort: "points", dir: "desc"
          )

          header = Nokogiri::HTML(response.body)
                           .css("thead tr")[1].css("th")
                           .find { |th| th["aria-sort"] == "descending" }

          expect(header.at_css("a")["href"]).to include("dir=asc")
        end
      end

      # An unmarked sheet holds back everyone at once, so the warning belongs on
      # the assignment's column, not on each student's row.
      context "with submissions still awaiting marking" do
        let(:assignment) do
          FactoryBot.create(:assignment, :expired, :with_lecture, lecture: lecture)
        end
        let(:assessment) do
          FactoryBot.create(:assessment, :with_points, assessable: assignment,
                                                       lecture: lecture)
        end
        let!(:task) do
          FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
        end
        let(:student) { FactoryBot.create(:confirmed_user) }

        before do
          FactoryBot.create(:student_performance_record,
                            lecture: lecture, user: student)
        end

        it "marks the assignment column when something is unmarked" do
          FactoryBot.create(:assessment_participation, :submitted,
                            assessment: assessment, user: student)

          get lecture_student_performance_records_path(lecture)

          expect(response.body).to include("bi-hourglass-split")
          expect(response.body).to include(
            I18n.t("student_performance.records.index.awaiting_marking", count: 1)
          )
        end

        it "does not mark the column once everything is marked" do
          FactoryBot.create(:assessment_participation, :reviewed,
                            assessment: assessment, user: student)

          get lecture_student_performance_records_path(lecture)

          expect(response.body).not_to include("bi-hourglass-split")
        end

        it "does not mark the column for work that was never handed in" do
          FactoryBot.create(:assessment_participation, :pending,
                            assessment: assessment, user: student)

          get lecture_student_performance_records_path(lecture)

          expect(response.body).not_to include("bi-hourglass-split")
        end

        it "counts only the students the filter shows" do
          other = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:student_performance_record, lecture: lecture, user: other)
          FactoryBot.create(:assessment_participation, :submitted,
                            assessment: assessment, user: student)
          FactoryBot.create(:assessment_participation, :submitted,
                            assessment: assessment, user: other)

          get lecture_student_performance_records_path(lecture, tutorial_id: "none")

          expect(response.body).to include(
            I18n.t("student_performance.records.index.awaiting_marking", count: 2)
          )
        end
      end

      context "with pagination" do
        before do
          26.times do
            FactoryBot.create(:student_performance_record,
                              lecture: lecture)
          end
        end

        it "paginates results" do
          get lecture_student_performance_records_path(lecture)
          expect(response).to have_http_status(:success)
          pagy = controller.instance_variable_get(:@pagy)
          expect(pagy).to be_present
          expect(pagy.count).to eq(26)
        end

        # Two students may share a name, and the order that puts them side by
        # side cannot say which comes first - so with OFFSET one of them can
        # turn up on both pages and somebody else on neither. Measured before
        # the tie-breaker: 100 rows, 99 of them different people.
        it "shows every student exactly once across the pages" do
          100.times do
            user = FactoryBot.create(:confirmed_user,
                                     name: "Max Mustermann",
                                     name_in_tutorials: "Max Mustermann")
            FactoryBot.create(:student_performance_record,
                              lecture: lecture, user: user)
          end

          seen = (1..6).flat_map do |page|
            get(lecture_student_performance_records_path(lecture, page: page))
            Nokogiri::HTML(response.body)
                    .css("#performance-records-frame tbody tr").pluck("id")
          end

          expect(seen.uniq.size).to eq(seen.size)
        end

        # A sorted table is an Array by the time it is cut into pages, and a
        # page is a page either way.
        it "still cuts the list into pages when a column is sorted" do
          get lecture_student_performance_records_path(
            lecture, sort: "percentage", dir: "desc"
          )

          expect(Nokogiri::HTML(response.body).css("tbody tr").size).to eq(20)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when lecture does not exist" do
      before { sign_in editor }

      it "redirects to root" do
        get lecture_student_performance_records_path(lecture_id: "nonexistent")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /lectures/:lecture_id/performance/records/:id" do
    let!(:record) do
      FactoryBot.create(:student_performance_record, lecture: lecture)
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get lecture_student_performance_record_path(lecture, record)
        expect(response).to have_http_status(:success)
      end

      # A list has room for a sheet that is not due yet, and the badge writes
      # out what it is instead of coding it into a colour. That is why the
      # overview may drop the column and this page may not.
      it "says the sheet is not due instead of marking it missing" do
        assignment = FactoryBot.create(:assignment, lecture: lecture,
                                                    deadline: 3.days.from_now)
        FactoryBot.create(:assessment_task,
                          assessment: assignment.assessment, max_points: 16)

        get lecture_student_performance_record_path(lecture, record)

        expect(response.body).to include(
          I18n.t("student_performance.records.columns.not_due")
        )
        expect(response.body).not_to include(
          I18n.t("student_performance.records.columns.not_submitted")
        )
      end

      it "says a sheet collected on paper is not recorded yet and offers the exemption" do
        assignment = FactoryBot.create(:assignment, :expired, lecture: lecture,
                                                              requires_submission: false)
        FactoryBot.create(:assessment_task,
                          assessment: assignment.assessment, max_points: 16)

        get lecture_student_performance_record_path(lecture, record)

        expect(response.body).to include(
          I18n.t("student_performance.records.columns.awaiting_record")
        )
        expect(response.body).not_to include(
          I18n.t("student_performance.records.columns.not_submitted")
        )
        expect(response.body).to include(I18n.t("student_performance.records.show.exempt"))
      end

      # Nobody can mark a sheet before its deadline, so a file handed in early
      # is not waiting on anyone.
      it "says an early hand-in is not due rather than waiting to be marked" do
        assignment = FactoryBot.create(:assignment, lecture: lecture,
                                                    deadline: 3.days.from_now)
        FactoryBot.create(:assessment_participation, :submitted,
                          assessment: assignment.assessment, user: record.user)

        get lecture_student_performance_record_path(lecture, record)

        expect(response.body).to include(
          I18n.t("student_performance.records.columns.not_due")
        )
        expect(response.body).not_to include(
          I18n.t("student_performance.records.columns.pending_grading")
        )
      end

      it "scopes record to the lecture" do
        other_lecture = FactoryBot.create(:lecture)
        other_record = FactoryBot.create(:student_performance_record,
                                         lecture: other_lecture)
        get lecture_student_performance_record_path(lecture, other_record)
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
      end

      it "redirects when record does not exist" do
        get lecture_student_performance_record_path(lecture, id: "nonexistent")
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
      end

      it "adds noopener to manuscript and correction links" do
        assignment = FactoryBot.create(:assignment,
                                       :with_lecture,
                                       lecture: lecture)
        FactoryBot.create(:assessment,
                          :with_points,
                          assessable: assignment,
                          lecture: lecture)
        submission = FactoryBot.create(:valid_submission,
                                       :with_manuscript,
                                       :with_correction,
                                       lecture: lecture,
                                       assignment: assignment)
        FactoryBot.create(:user_submission_join,
                          user: record.user,
                          submission: submission)

        get lecture_student_performance_record_path(lecture, record)

        expect(response.body).to include(
          %(href="#{show_submission_manuscript_path(submission)}")
        )
        expect(response.body).to include(
          %(href="#{show_correction_path(submission)}")
        )
        expect(response.body.scan(%(target="_blank" rel="noopener")).size)
          .to eq(2)
      end

      it "renders a dash when percentage is unavailable" do
        record.update!(percentage_materialized: nil,
                       points_total_materialized: 0,
                       points_max_materialized: 0)

        get lecture_student_performance_record_path(lecture, record)

        expect(response.body).to include(
          I18n.t("student_performance.records.percentage_unavailable")
        )
        expect(response.body).not_to include(">0%</div>")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_student_performance_record_path(lecture, record)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # A certificate is decided per person, here: an exempt sheet leaves the
  # reckoning for this student, and the note stays with the decision.
  describe "PATCH /lectures/:lecture_id/performance/records/:id/exempt" do
    let(:member) { FactoryBot.create(:confirmed_user) }
    # Joining the roster computes the record; the page is reached through it.
    let!(:record) do
      FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
      lecture.student_performance_records.find_by!(user: member)
    end
    let(:assignment) do
      FactoryBot.create(:assignment, :expired, lecture: lecture, title: "Sheet 3")
    end
    let(:assessment) { assignment.assessment }

    def exempt(sheet = assessment, note: nil)
      patch(exempt_lecture_student_performance_record_path(lecture, record),
            params: { assessment_id: sheet.id, note: note })
    end

    context "as an editor" do
      before { sign_in editor }

      it "exempts a sheet nothing was handed in for, with the note" do
        FactoryBot.create(:assessment_participation, :pending,
                          assessment: assessment, user: member)

        exempt(note: "Certificate until May 17")

        expect(response).to redirect_to(
          lecture_student_performance_record_path(lecture, record)
        )
        participation = assessment.assessment_participations.find_by(user: member)
        expect(participation).to be_exempt
        expect(participation.note).to eq("Certificate until May 17")
        expect(flash[:notice]).to eq(
          I18n.t("student_performance.records.show.exempted", sheet: "Sheet 3")
        )
      end

      it "makes the row the backfill has not made yet" do
        exempt

        participation = assessment.assessment_participations.find_by(user: member)
        expect(participation).to be_exempt
      end

      it "takes the sheet out of the student's maximum" do
        FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10)
        StudentPerformance::ComputationService.new(lecture: lecture)
                                              .compute_and_upsert_record_for(member)
        expect(record.reload.points_max_materialized).to eq(10)

        exempt

        expect(record.reload.points_max_materialized).to eq(0)
      end

      it "refuses a sheet the student handed in with a team" do
        tutorial = FactoryBot.create(:tutorial, lecture: lecture)
        FactoryBot.create(:submission, :with_manuscript, assignment: assignment,
                                                         tutorial: tutorial).users << member

        exempt

        expect(response).to redirect_to(
          lecture_student_performance_record_path(lecture, record)
        )
        expect(flash[:alert]).to include(
          I18n.t("activerecord.errors.models.assessment/participation.attributes" \
                 ".status.handed_in")
        )
        expect(assessment.assessment_participations.find_by(user: member)).to be_nil
      end

      it "refuses a sheet the tutor took on paper" do
        FactoryBot.create(:assessment_participation, :submitted,
                          assessment: assessment, user: member)

        exempt

        expect(flash[:alert]).to be_present
        expect(assessment.assessment_participations.find_by(user: member)).to be_pending
      end

      it "says so for a sheet of another lecture" do
        foreign = FactoryBot.create(:assignment, :expired, lecture: FactoryBot.create(:lecture))

        exempt(foreign.assessment)

        expect(flash[:alert]).to eq(I18n.t("student_performance.errors.no_sheet"))
      end

      it "revokes the exemption again" do
        exempt(note: "Certificate")

        patch unexempt_lecture_student_performance_record_path(lecture, record),
              params: { assessment_id: assessment.id }

        participation = assessment.assessment_participations.find_by(user: member)
        expect(participation).to be_pending
        expect(participation.note).to be_nil
        expect(flash[:notice]).to eq(
          I18n.t("student_performance.records.show.unexempted", sheet: "Sheet 3")
        )
      end
    end

    # Tutors enter points; a certificate is above their pay grade.
    context "as a tutor of the student's group" do
      let(:tutor) { FactoryBot.create(:confirmed_user) }

      before do
        tutorial = FactoryBot.create(:tutorial, lecture: lecture)
        tutorial.tutors << tutor
        FactoryBot.create(:tutorial_membership, tutorial: tutorial, user: member)
        sign_in tutor
      end

      it "is turned away" do
        exempt

        expect(response).to redirect_to(root_path)
        expect(assessment.assessment_participations.find_by(user: member)).to be_nil
      end
    end
  end

  describe "POST /lectures/:lecture_id/performance/records/recompute" do
    context "as an editor" do
      before { sign_in editor }

      it "redirects with alert when no user_id is given" do
        post(recompute_lecture_student_performance_records_path(lecture))
        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
        expect(flash[:alert]).to eq(
          I18n.t("student_performance.errors.no_member")
        )
      end

      it "computes inline for a single student and redirects" do
        user = FactoryBot.create(:confirmed_user)
        FactoryBot.create(:lecture_membership, user: user, lecture: lecture)

        post(recompute_lecture_student_performance_records_path(lecture),
             params: { user_id: user.id })

        record = lecture.student_performance_records
                        .find_by(user_id: user.id)
        expect(response).to redirect_to(
          lecture_student_performance_record_path(lecture, record)
        )
      end

      it "redirects with alert when user_id is not a lecture member" do
        outsider = FactoryBot.create(:confirmed_user)

        post(recompute_lecture_student_performance_records_path(lecture),
             params: { user_id: outsider.id })

        expect(response).to redirect_to(
          lecture_student_performance_records_path(lecture)
        )
        expect(flash[:alert]).to eq(
          I18n.t("student_performance.errors.no_member")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post recompute_lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
