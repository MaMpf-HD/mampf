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
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:roster_maintenance)
    assignment.reload
    assessment.reload
  end

  after do
    Flipper.disable(:assessment_grading)
    Flipper.disable(:registration_campaigns)
    Flipper.disable(:roster_maintenance)
  end

  # PATCH update_team_multi (tutorial)
  # this only applicable for tutor
  describe "PATCH /submissions/point_multi_submissions { type: Tutorial }" do
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

        it "calls SubmissionGraderService.score_tasks_by_types!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_types!)
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                          submissions: payload },
                as: :turbo_stream
        end

        it "returns turbo_stream" do
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                          mode: "tutor",
                          submissions: payload },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response).to have_http_status(:success)
        end
      end

      context "with a participation target" do
        let!(:participation) do
          create(:assessment_participation, assessment: assessment, user: student,
                                            tutorial: tutorial)
        end
        let(:payload) do
          [{ "target" => "participation",
             "id" => participation.id,
             "task_points" => { task.id => "5" } }].to_json
        end

        it "calls SubmissionGraderService.score_tasks_by_types!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_types!)
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                          submissions: payload },
                as: :turbo_stream
        end
      end

      context "when assignment is not found" do
        it "returns turbo_stream with alert" do
          patch point_multi_submissions_tutorial_path,
                params: { tutorial_id: tutorial.id, assignment_id: 999_999,
                          submissions: [].to_json },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
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
                        submissions: payload },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(
          I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
        )
      end
    end

    context "after deadline before grace period" do
      let(:submission) do
        create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
      end
      let(:payload) do
        [{ "target" => "submission",
           "id" => submission.id,
           "task_points" => { task.id => "7" } }].to_json
      end

      before { Timecop.travel(2.hours.from_now) }
      after { Timecop.return }

      it "returns turbo_stream with alert" do
        patch point_multi_submissions_tutorial_path,
              params: { tutorial_id: tutorial.id, assignment_id: assignment.id,
                        submissions: payload },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(
          I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
        )
      end
    end
  end

  # PATCH point_submission_tutorial
  describe "PATCH /submissions/:submission_id/point_submission { type: Tutorial }" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial, users: [student])
    end

    context "as tutor" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end

      context "after grace period" do
        before do
          sign_in teacher
          Timecop.travel(3.hours.from_now)
        end
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "tutor" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, type: "Tutorial",
                          mode: "tutor" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
        end

        context "when submission is not found" do
          it "responds with turbo_stream alert" do
            patch point_submission_tutorial_path(999_999),
                  params: { task_points: {}.to_json, mode: "tutor" },
                  as: :turbo_stream
            expect(response).to have_http_status(:success)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_submission")
            )
          end
        end
      end

      context "before deadline" do
        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "tutor" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "tutor" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end
    end

    context "as teacher" do
      before { sign_in teacher }
      context "after grace period" do
        before do
          sign_in teacher
          Timecop.travel(3.hours.from_now)
        end
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json,
                          type: "Tutorial",
                          mode: "teacher" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
        end

        context "when submission is not found" do
          it "responds with turbo_stream alert" do
            patch point_submission_tutorial_path(999_999),
                  params: { task_points: {}.to_json, mode: "teacher" },
                  as: :turbo_stream
            expect(response).to have_http_status(:success)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_submission")
            )
          end
        end
      end

      context "before deadline" do
        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "teacher" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "teacher" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end

      context "after deadline before grace period" do
        before { Timecop.travel(2.hours.from_now) }
        after { Timecop.return }
        it "calls SubmissionGraderService.score_tasks_by_submission!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_submission!)
            .and_return(nil)
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "teacher" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_submission_tutorial_path(submission),
                params: { task_points: { task.id => "8" }.to_json, mode: "teacher" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end
    end
  end

  # PATCH point_user_tutorial
  describe "PATCH /participations/:participation_id/point_user { type: Tutorial }" do
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: student, tutorial: tutorial)
    end

    context "as teacher" do
      before do
        sign_in teacher
        participation.reload
        student.reload
      end

      context "after grace period" do
        before do
          Timecop.travel(3.hours.from_now)
        end
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
          expect(participation.assessment.assessable).to eq(assignment)
          expect(assignment.grading_open?).to eq(true)
        end

        it "returns turbo_stream success" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
          puts response.body if response.status == 500
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        context "when participation is not found" do
          it "responds with turbo_stream alert" do
            patch point_user_tutorial_path(999_999),
                  params: { task_points: {}.to_json, mode: "teacher" },
                  as: :turbo_stream
            expect(response).to have_http_status(:success)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_participation")
            )
          end
        end
      end

      context "before deadline" do
        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end

      context "after deadline before grace period" do
        before { Timecop.travel(2.hours.from_now) }
        after { Timecop.return }
        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "teacher" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end
    end

    context "as tutor" do
      before do
        tutorial.tutors << tutor
        sign_in tutor
      end

      context "after grace period" do
        before do
          Timecop.travel(3.hours.from_now)
        end
        after { Timecop.return }

        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
        end

        it "returns turbo_stream success" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end

        context "when participation is not found" do
          it "responds with turbo_stream alert" do
            patch point_user_tutorial_path(999_999),
                  params: { task_points: {}.to_json, mode: "tutor" },
                  as: :turbo_stream
            expect(response).to have_http_status(:success)
            expect(response.media_type).to eq(Mime[:turbo_stream])
            expect(response.body).to include(
              I18n.t("assessment.errors.no_participation")
            )
          end
        end
      end

      context "before deadline" do
        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
      end

      context "after deadline before grace period" do
        before { Timecop.travel(2.hours.from_now) }
        after { Timecop.return }
        it "calls SubmissionGraderService.score_tasks_by_participation!" do
          expect(Assessment::SubmissionGraderService).to receive(:score_tasks_by_participation!)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
        end

        it "returns turbo_stream alert" do
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json, mode: "tutor" },
                as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include(
            I18n.t("assessment.task_points.cannot_score_not_grading_open_assignment")
          )
        end
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
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when submission is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_point_submission_tutorial_path(999_999),
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include(I18n.t("assessment.errors.no_submission"))
      end
    end
  end

  # PATCH refresh_point_user_tutorial
  describe "PATCH /participations/:participation_id/refresh_point_user" do
    let!(:participation) do
      create(:assessment_participation, assessment: assessment, user: student)
    end

    before { sign_in teacher }

    it "returns turbo_stream success" do
      patch refresh_point_user_tutorial_path(participation),
            as: :turbo_stream
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when participation is not found" do
      it "responds with turbo_stream alert" do
        patch refresh_point_user_tutorial_path(999_999),
              as: :turbo_stream
        expect(response).to have_http_status(:success)
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

      it "calls SubmissionGraderService.init_participation" do
        expect(Assessment::SubmissionGraderService).to receive(:init_participation)
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id,
                        user_id: student.id, mode: "tutor" },
              as: :turbo_stream
      end

      it "returns turbo_stream success" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, mode: "tutor",
                        user_id: student.id },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      context "when user is not found" do
        it "calls init_participation with nil user and does not raise" do
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id,
                          user_id: 999_999, mode: "tutor" },
                as: :turbo_stream
          expect(response.media_type).to eq(Mime[:turbo_stream])
        end
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
              params: { task_points: {}.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end

      it "redirects point_user to sign in" do
        participation = create(:assessment_participation, assessment: assessment,
                                                          user: student)
        patch point_user_tutorial_path(participation),
              params: { task_points: {}.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user cannot edit lecture (student)" do
      before do
        sign_in student
      end
      after { Timecop.return }

      it "redirects point_submission to root" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end

      it "redirects point_user to root" do
        participation = create(:assessment_participation, assessment: assessment, user: student,
                                                          tutorial: tutorial)
        Timecop.travel(3.hours.from_now)
        patch point_user_tutorial_path(participation),
              params: { task_points: { task.id => "6" }.to_json },
              as: :turbo_stream
        expect(response).to redirect_to(root_path)
      end

      it "redirects mark_as_participated to root" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                        user_id: student.id },
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

      it "allows point_submission" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "allows point_user" do
        participation = create(:assessment_participation, assessment: assessment, user: student,
                                                          tutorial: tutorial)
        Timecop.travel(3.hours.from_now)
        patch point_user_tutorial_path(participation),
              params: { task_points: { task.id => "6" }.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "allows mark_as_participated" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, mode: "tutor",
                        user_id: student.id },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is a teacher (lecture teacher)" do
      let(:teacher) { create(:confirmed_user) }

      before do
        lecture.update(teacher: teacher)
        sign_in teacher
      end

      after { Timecop.return }

      it "allows point_submission" do
        submission = create(:submission, assignment: assignment, tutorial: tutorial,
                                         users: [student])
        Timecop.travel(3.hours.from_now)
        patch point_submission_tutorial_path(submission),
              params: { task_points: { task.id => "8" }.to_json },
              as: :turbo_stream

        expect(response).to have_http_status(:success)
      end

      it "allows point_user" do
        Timecop.travel(3.hours.from_now)
        participation = create(:assessment_participation, :submitted,
                               assessment: assessment, tutorial: tutorial, user: student)

        patch point_user_tutorial_path(participation),
              params: { task_points: { task.id => "6" }.to_json },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      it "allows mark_as_participated" do
        patch mark_user_as_participated_path,
              params: { assignment_id: assignment.id, mode: "tutor",
                        user_id: student.id },
              as: :turbo_stream
        expect(response).to have_http_status(:success)
      end

      context "when user is a teacher (not lecture teacher)" do
        let("teacher") { create(:confirmed_user) }
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
                params: { task_points: { task.id => "8" }.to_json },
                as: :turbo_stream
          expect(response).to redirect_to(root_path)
        end

        it "redirects point_user to root" do
          participation = create(:assessment_participation, assessment: assessment, user: student,
                                                            tutorial: tutorial)
          patch point_user_tutorial_path(participation),
                params: { task_points: { task.id => "6" }.to_json },
                as: :turbo_stream
          expect(response).to redirect_to(root_path)
        end

        it "redirects mark_as_participated to root" do
          patch mark_user_as_participated_path,
                params: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                          user_id: student.id },
                as: :turbo_stream
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
