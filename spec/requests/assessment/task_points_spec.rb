require "rails_helper"

RSpec.describe("Assessment::TaskPoints", type: :request) do
  let(:teacher) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }

  let(:lecture) { create(:lecture, teacher: teacher, submission_grace_period: 70) }
  let!(:assignment) do
    FactoryBot.create(:assignment, deadline: 1.hour.from_now, lecture: lecture)
  end
  let!(:assessment) do
    FactoryBot.create(:assessment, :with_points, assessable: assignment)
  end
  let!(:task) { create(:assessment_task, assessment: assessment) }

  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:student) { create(:confirmed_user) }
  let!(:tutorial_membership) do
    create(:tutorial_membership, user: student, tutorial: tutorial)
  end
  let!(:lecture_membership) do
    create(:lecture_membership, user: student, lecture: lecture)
  end

  let(:tutorial2) { create(:tutorial, lecture: lecture) }
  let(:student2) { create(:confirmed_user) }
  let!(:tutorial_membership2) do
    create(:tutorial_membership, user: student2, tutorial: tutorial2)
  end
  let!(:lecture_membership2) do
    create(:lecture_membership, user: student2, lecture: lecture)
  end

  before do
    assignment.reload
    assessment.reload
  end

  # PATCH update_team_multi (tutorial)
  describe "PATCH /submissions/point_multi_submissions" do
    before do
      tutorial.tutors << tutor
      sign_in tutor
    end

    context "after grace period" do
      before { Timecop.travel(3.hours.from_now) }
      after { Timecop.return }

      context "with a submission target" do
        let(:submission) do
          create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
        end
        let(:payload) do
          [{ "target" => "submission",
             "id" => submission.id,
             "task_points" => { task.id => "7" } }].to_json
        end

        it "calls SubmissionGraderService.score_multi_teams_by_types!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_multi_teams_by_types!)
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                          grading_scope_type: "tutorial",
                          submissions: payload },
                as: :turbo_stream
        end

        it "returns turbo_stream" do
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                          grading_scope_type: "tutorial",
                          submissions: payload },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response).to have_http_status(:success)
        end
      end

      # The lecture's table names no group: it holds rows of every group and
      # of people in none, and only the lecturer saves from it.
      context "from the lecture's table" do
        let!(:ungrouped) do
          member = FactoryBot.create(:confirmed_user)
          FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          FactoryBot.create(:assessment_participation, :submitted, assessment: assessment,
                                                                   user: member, tutorial: nil)
        end
        let(:payload) do
          [{ "target" => "participation", "id" => ungrouped.id,
             "task_points" => { task.id => "3" } }].to_json
        end

        it "lets the lecturer save somebody in no group" do
          sign_in teacher
          patch point_multi_submissions_tutorial_path,
                params: { assignment_id: assignment.id, grading_scope_type: "lecture",
                          submissions: payload },
                as: :turbo_stream

          expect(response).to have_http_status(:success)
          expect(ungrouped.reload.task_points.find_by(task: task).points).to eq(3)
          expect(response.body).to include("target=\"pointing-table\"")
        end

        it "turns a tutor away" do
          patch point_multi_submissions_tutorial_path,
                params: { assignment_id: assignment.id, grading_scope_type: "lecture",
                          submissions: payload },
                as: :turbo_stream

          expect(response).to redirect_to(root_path)
          expect(ungrouped.reload.task_points).to be_empty
        end
      end

      context "when assignment is not found" do
        it "returns turbo_stream with alert" do
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: 999_999,
                          grading_scope_type: "tutorial",
                          submissions: [].to_json },
                as: :turbo_stream
          expect(response).to have_http_status(:not_found)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.errors.no_assignment")
          )
        end
      end

      context "when tutorial is not found" do
        it "responds with turbo_stream alert" do
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: 999_999, assignment_id: assignment.id,
                          grading_scope_type: "tutorial",
                          submissions: [].to_json },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end
    end

    context "before deadline" do
      let(:submission) do
        create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
      end
      let(:payload) do
        [{ "target" => "submission",
           "id" => submission.id,
           "task_points" => { task.id => "7" } }].to_json
      end

      it "returns turbo_stream with alert" do
        patch point_multi_submissions_tutorial_path,
              params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                        grading_scope_type: "tutorial",
                        submissions: payload },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end
    end
  end

  # PATCH point_submission_tutorial
  describe "PATCH /submissions/:submission_id/point_submission" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
    end

    context "as tutor" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end

      context "after grace period" do
        before { Timecop.travel(3.hours.from_now) }
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          grading_scope_type: "tutorial" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          grading_scope_type: "tutorial" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
        end

        context "when submission is not found" do
          it "responds with turbo_stream alert" do
            patch point_submission_tutorial_path(999_999),
                  params: { task_points: {}.to_json, grading_scope_type: "tutorial" },
                  as: :turbo_stream
            expect(response).to have_http_status(:not_found)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_submission")
            )
          end
        end
      end

      context "before deadline" do
        it "returns turbo_stream success" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          grading_scope_type: "tutorial" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end
    end

    context "as teacher" do
      before { sign_in teacher }

      context "after grace period" do
        before { Timecop.travel(3.hours.from_now) }
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          grading_scope_type: "lecture" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          grading_scope_type: "lecture" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  # PATCH point_user_tutorial (update_participation)
  describe "PATCH /participations/:participation_id/point_user" do
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: student, tutorial: tutorial)
    end

    context "as teacher, grading_scope_type=lecture" do
      before do
        sign_in teacher
        participation.reload
        student.reload
      end

      context "after grace period" do
        before { Timecop.travel(3.hours.from_now) }
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_participation_path(participation),
                params: { task_points: { task.id => "6" }.to_json,
                          grading_scope_type: "lecture" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_participation_path(participation),
                params: { task_points: { task.id => "6" }.to_json,
                          grading_scope_type: "lecture" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        context "when participation is not found" do
          it "responds with turbo_stream alert" do
            patch point_participation_path(999_999),
                  params: { task_points: {}.to_json, grading_scope_type: "lecture" },
                  as: :turbo_stream
            expect(response).to have_http_status(:not_found)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_participation")
            )
          end
        end
      end

      context "before deadline" do
        it "returns turbo_stream success" do
          patch point_participation_path(participation),
                params: { task_points: { task.id => "6" }.to_json,
                          grading_scope_type: "lecture" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end
    end

    context "as tutor, grading_scope_type=tutorial" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end

      context "after grace period" do
        before { Timecop.travel(3.hours.from_now) }
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_participation_path(participation),
                params: { task_points: { task.id => "6" }.to_json,
                          grading_scope_type: "tutorial" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_participation_path(participation),
                params: { task_points: { task.id => "6" }.to_json,
                          grading_scope_type: "tutorial" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
      end
    end

    # A sheet handed in on paper by somebody in no group: the participation
    # has no tutorial, and the lecture is what the grader is checked against.
    context "when the participation belongs to no group" do
      let!(:ungrouped) do
        create(:assessment_participation, assessment: assessment,
                                          user: create(:confirmed_user))
      end

      before { Timecop.travel(3.hours.from_now) }
      after { Timecop.return }

      it "is scored by the teacher" do
        sign_in teacher

        patch point_participation_path(ungrouped),
              params: { task_points: { task.id => "6" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream

        expect(response).to have_http_status(:success)
        expect(ungrouped.reload.task_points.pick(:points)).to eq(6)
      end

      it "is not scored by a tutor" do
        tutorial.tutors << tutor
        sign_in tutor

        patch point_participation_path(ungrouped),
              params: { task_points: { task.id => "6" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream

        expect(response).to redirect_to(root_path)
        expect(ungrouped.reload.task_points).to be_empty
      end
    end

    context "when the participation is not found" do
      before { sign_in teacher }

      it "says so with a 404" do
        patch point_participation_path("00000000-0000-0000-0000-000000000000"),
              params: { task_points: {}.to_json, grading_scope_type: "lecture" },
              as: :turbo_stream

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include(I18n.t("assessment.errors.no_participation"))
      end
    end

    # The rows of this page are drawn for sheets. Exams get their own table
    # later; until then a participation in one is refused, not half-served.
    context "when the participation's assessable is an Exam" do
      let(:exam) { create(:exam, lecture: lecture) }
      let(:exam_assessment) { create(:assessment, :with_points, assessable: exam) }
      let!(:exam_participation) do
        create(:assessment_participation, assessment: exam_assessment, user: student)
      end

      before { sign_in teacher }

      it "refuses with a 400 and enters nothing" do
        expect(Assessment::SubmissionGraderService).not_to receive(:score_tasks_by_participation!)

        patch point_participation_path(exam_participation),
              params: { task_points: { task.id => "6" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream

        expect(response).to have_http_status(:bad_request)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(
          I18n.t("assessment.task_points.unsupported_assessment_type")
        )
      end

      it "refuses a refresh the same way" do
        patch refresh_point_participation_path(exam_participation),
              params: { grading_scope_type: "lecture" }, as: :turbo_stream

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when the participation's assessable is a talk" do
      let(:seminar) { create(:seminar, teacher: teacher) }
      let(:talk) { create(:talk, lecture: seminar) }
      let(:talk_assessment) { create(:assessment, :with_points, assessable: talk) }
      let!(:talk_participation) do
        create(:assessment_participation, assessment: talk_assessment, user: student)
      end

      before { sign_in teacher }

      it "refuses with a 400" do
        patch point_participation_path(talk_participation),
              params: { task_points: { task.id => "6" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to include(
          I18n.t("assessment.task_points.unsupported_assessment_type")
        )
      end
    end
  end

  # PATCH refresh_point_submission_tutorial
  describe "PATCH /submissions/:submission_id/refresh_point_submission" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
    end

    before { sign_in teacher }

    it "returns turbo_stream success" do
      patch refresh_point_submission_tutorial_path(submission),
            params: { grading_scope_type: "lecture" },
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when submission is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_point_submission_tutorial_path(999_999),
              params: { grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(I18n.t("assessment.errors.no_submission"))
      end
    end
  end

  # PATCH refresh_point_participation
  describe "PATCH /participations/:participation_id/refresh_point_user" do
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: student)
    end

    before { sign_in teacher }

    it "returns turbo_stream success" do
      patch refresh_point_participation_path(participation),
            params: { grading_scope_type: "lecture" },
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when participation is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_point_participation_path(999_999),
              params: { grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(I18n.t("assessment.errors.no_participation"))
      end
    end
  end

  # PATCH mark_user_as_participated
  describe "PATCH /participations/mark_as_participated" do
    context "as tutor" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end

      it "records the paper hand-in and answers with the student's row" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, user_id: student.id,
                        tutorial_id: tutorial.id, grading_scope_type: "tutorial" },
              as: :turbo_stream

        participation = assessment.assessment_participations.find_by(user: student)
        expect(participation.submitted_at).to be_present
        expect(response.body).to include("target=\"participation-row-user-#{student.id}\"")
        expect(response.body).to include("participation-row-#{participation.id}")
      end

      # The tutor's page lists one group; a row drawn for the lecture's page
      # would bring the group column with it.
      it "draws the row in the shape of the page's group" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, user_id: student.id,
                        tutorial_id: tutorial.id, grading_scope_type: "tutorial" },
              as: :turbo_stream

        expect(response.body).not_to include(tutorial.title)
      end

      it "names the group in the row drawn for the lecture's page" do
        sign_in teacher
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, user_id: student.id,
                        grading_scope_type: "lecture" },
              as: :turbo_stream

        expect(response.body).to include(tutorial.title)
      end

      it "answers with the row alone when the student already has one" do
        participation = FactoryBot.create(:assessment_participation,
                                          assessment: assessment, user: student,
                                          tutorial: tutorial, submitted_at: nil)

        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, user_id: student.id,
                        tutorial_id: tutorial.id, grading_scope_type: "tutorial" },
              as: :turbo_stream

        expect(participation.reload.submitted_at).to be_present
        expect(response.body).to include("target=\"participation-row-#{participation.id}\"")
        expect(response.body).not_to include("target=\"pointing-table\"")
      end

      context "when user is not found" do
        it "does not call init_participation" do
          expect(Assessment::SubmissionGraderService).not_to receive(:init_participation)
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, user_id: 999_999 },
                as: :turbo_stream
        end

        it "sets an alert flash message" do
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, user_id: 999_999 },
                as: :turbo_stream
          expect(flash[:alert]).to eq(I18n.t("assessment.errors.user_not_found"))
        end
      end

      # A member in no group takes part in the lecture itself, and that is the
      # lecturer's row, not a tutor's.
      context "when the member is in no group" do
        let!(:ungrouped) do
          FactoryBot.create(:confirmed_user).tap do |member|
            FactoryBot.create(:lecture_membership, lecture: lecture, user: member)
          end
        end

        it "is turned away as a tutor" do
          expect(Assessment::SubmissionGraderService).not_to receive(:init_participation)
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, user_id: ungrouped.id },
                as: :turbo_stream

          expect(response).to redirect_to(root_path)
        end

        it "records the paper hand-in as the teacher, in no group" do
          sign_in teacher
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, user_id: ungrouped.id,
                          grading_scope_type: "lecture" },
                as: :turbo_stream

          participation = assessment.assessment_participations.find_by(user: ungrouped)
          expect(participation.tutorial_id).to be_nil
          expect(participation.submitted_at).to be_present
        end
      end

      context "when the user is not a member of the lecture" do
        it "says so with a 404" do
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id,
                          user_id: FactoryBot.create(:confirmed_user).id },
                as: :turbo_stream

          expect(response).to have_http_status(:not_found)
        end
      end

      # The sheet is with the group that holds the participation; the tutor
      # of the group somebody moved into may not touch it.
      context "when another group holds the participation" do
        let!(:held_elsewhere) do
          FactoryBot.create(:assessment_participation, assessment: assessment,
                                                       user: student, tutorial: tutorial2,
                                                       submitted_at: nil)
        end

        it "turns the tutor of the current group away and stamps nothing" do
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, user_id: student.id,
                          tutorial_id: tutorial.id, grading_scope_type: "tutorial" },
                as: :turbo_stream

          expect(response).to redirect_to(root_path)
          expect(held_elsewhere.reload.submitted_at).to be_nil
        end

        it "turns the tutor away from the pile as well" do
          patch mark_users_as_participated_path,
                params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                          grading_scope_type: "tutorial", user_ids: [student.id] },
                as: :turbo_stream

          expect(response).to redirect_to(root_path)
          expect(held_elsewhere.reload.submitted_at).to be_nil
        end
      end

      # This page draws rows for assignments; an exam participation has no
      # row to go back into and must not be stamped on the way.
      context "when the participation named is an exam's" do
        let(:exam) { create(:exam, lecture: lecture) }
        let(:exam_assessment) { create(:assessment, :with_points, assessable: exam) }
        let!(:exam_participation) do
          create(:assessment_participation, assessment: exam_assessment, user: student,
                                            submitted_at: nil)
        end

        it "refuses with a 400 and stamps nothing" do
          sign_in teacher
          patch mark_user_as_participated_path,
                params: { participation_id: exam_participation.id, user_id: student.id,
                          grading_scope_type: "lecture" },
                as: :turbo_stream

          expect(response).to have_http_status(:bad_request)
          expect(exam_participation.reload.submitted_at).to be_nil
        end
      end
    end
  end

  describe "PATCH /participations/mark_as_participated_multi" do
    let(:classmate) { create(:confirmed_user) }

    before do
      create(:tutorial_membership, user: classmate, tutorial: tutorial)
      create(:lecture_membership, user: classmate, lecture: lecture)
      tutorial.tutors << tutor
      sign_in tutor
    end

    it "records the pile and answers with one row per sheet" do
      patch mark_users_as_participated_path,
            params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      grading_scope_type: "tutorial",
                      user_ids: [student.id, classmate.id] },
            as: :turbo_stream

      stamped = assessment.assessment_participations.where(user: [student, classmate])
      expect(stamped.map(&:submitted_at)).to all(be_present)
      expect(response.body.scan("<turbo-stream").size).to eq(3)
      expect(response.body).to include("target=\"participation-row-user-#{student.id}\"")
      expect(response.body).to include("target=\"participation-row-user-#{classmate.id}\"")
      expect(response.body).to include("target=\"pointing-summary\"")
    end

    # One sheet the tutor may not mark rolls the whole pile back.
    it "records nothing when one of the sheets is another group's" do
      patch mark_users_as_participated_path,
            params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      grading_scope_type: "tutorial",
                      user_ids: [student.id, student2.id] },
            as: :turbo_stream

      expect(response).to redirect_to(root_path)
      expect(assessment.assessment_participations.where(user: [student, student2])).to be_empty
    end

    it "records nothing when one of the ids is nobody's" do
      patch mark_users_as_participated_path,
            params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      grading_scope_type: "tutorial",
                      user_ids: [student.id, FactoryBot.create(:confirmed_user).id] },
            as: :turbo_stream

      expect(response).to have_http_status(:not_found)
      expect(assessment.assessment_participations.where(user: student)).to be_empty
    end

    it "answers with no row for an empty selection" do
      patch mark_users_as_participated_path,
            params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      grading_scope_type: "tutorial" },
            as: :turbo_stream

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("participation-row-")
    end
  end

  # PATCH remove_participated
  describe "PATCH /participations/remove_participated" do
    before do
      tutorial.tutors << tutor
      sign_in tutor
    end

    let!(:participation) do
      FactoryBot.create(:assessment_participation,
                        assessment: assessment, user: student, tutorial: tutorial)
    end

    it "calls SubmissionGraderService.remove_participation" do
      expect(Assessment::SubmissionGraderService).to receive(:remove_participation)
        .and_return(participation)
      patch remove_participation_path(participation),
            params: { grading_scope_type: "tutorial" },
            as: :turbo_stream
    end

    it "answers with the row alone" do
      patch remove_participation_path(participation),
            params: { grading_scope_type: "tutorial" },
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("target=\"participation-row-#{participation.id}\"")
      expect(response.body).not_to include("target=\"pointing-table\"")
    end

    context "when the participation has task points with points assigned" do
      let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment) }

      before do
        Timecop.travel(3.hours.from_now)
        create(:assessment_task_point,
               assessment_participation: participation, task: task2, points: 0)
      end
      after { Timecop.return }

      it "does not destroy the participation" do
        patch remove_participation_path(participation),
              params: { grading_scope_type: "tutorial" }, as: :turbo_stream
        expect(Assessment::Participation.exists?(participation.id)).to be(true)
      end
    end

    context "when the participation has no task points" do
      it "takes the stamp off and keeps the row" do
        participation.update!(submitted_at: 1.day.ago)

        patch remove_participation_path(participation),
              params: { grading_scope_type: "tutorial" }, as: :turbo_stream

        expect(participation.reload.submitted_at).to be_nil
      end
    end
  end

  # Authorization
  describe "authorization" do
    context "when user is not signed in" do
      it "redirects point_submission to sign in" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        patch point_submission_tutorial_path(submission),
              params: { task_points: {}.to_json, grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end

      it "redirects point_user to sign in" do
        participation = create(:assessment_participation, assessment: assessment, user: student)
        patch point_participation_path(participation),
              params: { task_points: {}.to_json, grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user cannot edit lecture (student)" do
      before { sign_in student }
      after { Timecop.return }

      it "redirects point_submission to root" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end

      it "redirects point_user to root" do
        participation = create(:assessment_participation, assessment: assessment, user: student,
                                                          tutorial: tutorial)
        Timecop.travel(3.hours.from_now)
        patch point_participation_path(participation),
              params: { task_points: { task.id => "6" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is a tutor" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end
      after { Timecop.return }

      it "allows point_submission with grading_scope_type=tutorial" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      # The page hint says which table the row goes back into; who may grade
      # follows the hand-in's own group, whatever the hint says.
      it "allows point_submission on the group's hand-in whatever the page says" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "denies point_submission on another group's hand-in whatever the page says" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial2,
                                         users: [student2])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
        expect(submission.users.first.assessment_participations).to be_empty
      end

      it "denies point_participation on another group's participation" do
        other = create(:assessment_participation, assessment: assessment, user: student2,
                                                  tutorial: tutorial2)
        Timecop.travel(3.hours.from_now)
        patch point_participation_path(other),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "tutorial" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
        expect(other.reload.task_points).to be_empty
      end
    end

    context "when grading_scope_type is missing or invalid" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
        Timecop.travel(3.hours.from_now)
      end
      after { Timecop.return }

      it "still grades the group's hand-in without a grading_scope_type" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "still grades the group's hand-in with a bogus grading_scope_type" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "bogus" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is the lecture teacher" do
      before do
        lecture.update(teacher: teacher)
        sign_in teacher
      end
      after { Timecop.return }

      it "allows point_submission with grading_scope_type=lecture" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a teacher but not this lecture's teacher" do
      let(:other_teacher) { create(:confirmed_user) }

      before do
        lecture.update(teacher: teacher)
        sign_in other_teacher
        Timecop.travel(3.hours.from_now)
      end
      after { Timecop.return }

      it "redirects point_submission to root" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json,
                        grading_scope_type: "lecture" },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
