require "rails_helper"

RSpec.describe("StudentPerformance::Records", type: :request) do
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

      context "with achievements" do
        before { Flipper.enable(:assessment_grading) }

        after { Flipper.disable(:assessment_grading) }

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
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_student_performance_records_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when feature flag is disabled" do
      before do
        Flipper.disable(:student_performance)
        sign_in editor
      end

      it "falls through to catch-all and redirects" do
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
