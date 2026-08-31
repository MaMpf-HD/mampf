require "rails_helper"

RSpec.describe("Submissions", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture, accepted_file_type: ".pdf") }
  let(:tutorial) { create(:tutorial, lecture: lecture) }

  before do
    sign_in user
  end

  describe "GET /submissions/:id/show_manuscript" do
    let(:submission) do
      create(:submission, :with_manuscript, assignment: assignment,
                                            tutorial: tutorial).tap do |record|
        record.users << user
      end
    end

    it "sanitizes the manuscript filename from uploaded metadata" do
      allow_any_instance_of(SubmissionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get show_submission_manuscript_path(submission)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("inline")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end

    it "serves a content-sniffed text/html manuscript as text/plain (FU-01)" do
      submission.reload # create with real application/pdf metadata before stubbing

      allow_any_instance_of(SubmissionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("mime_type" => "text/html")
        end

      get show_submission_manuscript_path(submission)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
    end

    it "still serves a PDF manuscript inline as application/pdf" do
      get show_submission_manuscript_path(submission)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("inline")
    end
  end

  describe "GET /submissions/:id/show_correction" do
    let(:submission) do
      create(:submission, :with_correction, assignment: assignment,
                                            tutorial: tutorial).tap do |record|
        record.users << user
      end
    end

    it "sanitizes the correction filename from uploaded metadata" do
      allow_any_instance_of(CorrectionUploader::UploadedFile).to receive(:metadata)
        .and_wrap_original do |original, *args|
          original.call(*args).merge("filename" => "../evil\r\nname.pdf")
        end

      get show_correction_path(submission, download: true)

      content_disposition = response.headers["Content-Disposition"]

      expect(response).to have_http_status(:ok)
      expect(content_disposition).to include("attachment")
      expect(content_disposition).to include("evil")
      expect(content_disposition).to include("name.pdf")
      expect(content_disposition).not_to include("../")
      expect(content_disposition).not_to match(/[\r\n]/)
    end
  end

  describe "POST /submissions" do
    def create_params
      # the create form always sends a (possibly empty) manuscript field
      { submission: { assignment_id: assignment.id, tutorial_id: tutorial.id,
                      manuscript: "" } }
    end

    def create_params_no_tutorial
      # the create form always sends a (possibly empty) manuscript field
      { submission: { assignment_id: assignment.id,
                      manuscript: "" } }
    end

    it "lets a student enrolled in the lecture create a submission" do
      user.lectures << lecture
      expect { post(submissions_path(format: :js), params: create_params) }
        .to change(Submission, :count).by(1)
    end

    it "does not let a user not enrolled in the lecture create a submission" do
      expect { post(submissions_path(format: :js), params: create_params) }
        .not_to change(Submission, :count)
    end

    let(:other_tutorial) { create(:tutorial, lecture: lecture) }

    context "roster-eligible lecture, student not enrolled" do
      before do
        other_user = create(:confirmed_user)
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: other_tutorial, user: other_user)
      end

      it "does not create a submission and redirects to lecture submissions with an alert" do
        user.lectures << lecture
        expect { post(submissions_path(format: :js), params: create_params) }
          .not_to change(Submission, :count)

        expect(response).to redirect_to(start_path)
        follow_redirect!
        expect(flash[:alert]).to eq(
          I18n.t("submission.tutorial_not_assigned")
        )
      end
    end

    context "roster-eligible lecture, student enrolled" do
      before do
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: tutorial, user: user)
      end

      it "creates the submission on the student's rostered tutorial" do
        user.lectures << lecture
        expect { post(submissions_path(format: :js), params: create_params_no_tutorial) }
          .to change(Submission, :count).by(1)

        expect(Submission.last.tutorial).to eq(tutorial)
      end
    end
  end

  describe "a student without a rostered tutorial" do
    let!(:assignment) { create(:assignment, lecture: lecture, accepted_file_type: ".pdf") }
    let(:rostered) { create(:confirmed_user) }
    let(:foreign_submission) do
      create(:submission, assignment: assignment, tutorial: tutorial)
        .tap { |s| s.users << rostered }
    end

    before do
      create(:tutorial_membership, tutorial: tutorial, user: rostered)
      user.lectures << lecture
    end

    it "is not offered a way to create or join a submission" do
      get lecture_submissions_path(lecture)

      expect(response.body).not_to include("create-submission")
      expect(response.body).not_to include("submission-join")
      expect(response.body).to include(I18n.t("submission.tutorial_needed"))
    end

    it "cannot join by code, which is also how an invitation is accepted" do
      foreign_submission

      expect do
        post(join_submission_path(format: :js),
             params: { join: { code: foreign_submission.token,
                               assignment_id: assignment.id } })
      end.not_to change(UserSubmissionJoin, :count)
    end
  end

  describe "PATCH /submissions/:id" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial, users: [user])
    end

    def update_params(tutorial_id:)
      { submission: { tutorial_id: tutorial_id, manuscript: "" } }
    end

    let(:other_tutorial) { create(:tutorial, lecture: lecture) }

    context "roster-eligible lecture, student not enrolled" do
      before do
        other_user = create(:confirmed_user)
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: other_tutorial, user: other_user)
      end

      it "does not update the submission and redirects to lecture submissions with an alert" do
        # The form sends no tutorial_id in roster mode.
        patch submission_path(submission, format: :js),
              params: { submission: { manuscript: "" } }

        expect(response).to redirect_to(start_path)
        follow_redirect!
        expect(flash[:alert]).to eq(
          I18n.t("submission.tutorial_not_assigned")
        )
      end
    end

    context "roster-eligible lecture, student enrolled" do
      before do
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: tutorial, user: user)
      end

      it "updates the submission, keeping it on the student's rostered tutorial" do
        patch submission_path(submission, format: :js),
              params: update_params(tutorial_id: other_tutorial.id)

        expect(submission.reload.tutorial).to eq(tutorial)
      end
    end
  end

  describe "GET /lectures/:id/submissions" do
    let!(:assignments) { create_list(:assignment, 5, lecture: lecture, accepted_file_type: ".pdf") }

    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      user.lectures << lecture
    end

    it "queries roster_managed? once per lecture across all assignment rows" do
      expect_any_instance_of(Lecture).to receive(:roster_managed?)
        .once.and_call_original

      get lecture_submissions_path(lecture)
    end

    it "queries rostered_tutorial_in once per lecture across all assignment rows" do
      expect_any_instance_of(User).to receive(:rostered_tutorial_in)
        .once.and_call_original

      get lecture_submissions_path(lecture)
    end

    it "renders successfully with multiple assignment rows sharing the cache" do
      get lecture_submissions_path(lecture)

      expect(response).to have_http_status(:success)
    end
  end

  describe "the sheet list on GET /lectures/:id/submissions" do
    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      user.lectures << lecture
    end

    def sheet(title:, weeks_ago: 1, max_points: [4, 4])
      assignment = create(:assignment, :expired, lecture: lecture, title: title,
                                                 expired_since: weeks_ago.weeks)
      max_points.each do |points|
        create(:assessment_task, assessment: assignment.assessment,
                                 max_points: points)
      end
      assignment
    end

    def hand_in(assignment, correction: false)
      traits = [:with_manuscript]
      traits << :with_correction if correction
      submission = create(:submission, *traits, assignment: assignment,
                                                tutorial: tutorial)
      submission.users << user
      submission
    end

    def mark(assignment, points_per_task)
      participation = create(:assessment_participation,
                             assessment: assignment.assessment, user: user,
                             submitted_at: 3.days.ago)
      assignment.assessment.tasks.order(:position).each_with_index do |task, index|
        create(:assessment_task_point, task: task, points: points_per_task[index],
                                       assessment_participation: participation)
      end
      participation.reload.update!(status: :reviewed, graded_at: 2.days.ago)
    end

    describe "who gets in" do
      it "renders for a student of the lecture" do
        get lecture_submissions_path(lecture)

        expect(response).to have_http_status(:success)
      end

      it "turns a tutor of the lecture away" do
        create(:tutor_tutorial_join, tutorial: tutorial, tutor: user)

        get lecture_submissions_path(lecture)

        expect(response).to redirect_to(:root)
      end

      it "turns away somebody who is not in the lecture" do
        user.lectures.delete(lecture)

        get lecture_submissions_path(lecture)

        expect(response).to redirect_to(:root)
      end

      it "turns everybody away from a lecture without tutorials" do
        without_tutorials = create(:lecture, :released_for_all)
        user.lectures << without_tutorials

        get lecture_submissions_path(without_tutorials)

        expect(response).to redirect_to(:root)
      end

      # The page draws the first week of a term and a lecture whose sheets are
      # not up yet, and neither can be reached if the guard sends them away.
      it "renders a lecture that has no sheets at all" do
        get lecture_submissions_path(lecture)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t("submission.hub.no_sheets_yet"))
        expect(response.body).to include(I18n.t("assignment.no_current"))
      end
    end

    describe "what the rows say" do
      it "shows a marked sheet with its number and no badge" do
        mark(sheet(title: "Homework 8"), [1.5, 2])

        get lecture_submissions_path(lecture)

        expect(response.body).to include("Homework 8")
        expect(response.body).to include(
          I18n.t("submission.hub.points_reader", points: "3.5", max: "8")
        )
        expect(response.body)
          .not_to include(I18n.t("submission.hub.chips.awaiting_marks"))
      end

      it "shows a badge and no number for a sheet that has not come back" do
        create(:assessment_participation,
               assessment: sheet(title: "Homework 9").assessment,
               user: user, submitted_at: 8.days.ago)

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(I18n.t("submission.hub.chips.awaiting_marks"))
      end

      # Before the first sheet has come back, saying which one will land here
      # first is more use than saying "none".
      it "names the sheet the list is waiting for" do
        create(:assignment, lecture: lecture, title: "Homework 1",
                            deadline: 1.week.from_now)

        get lecture_submissions_path(lecture)

        expect(response.body).to include(
          I18n.t("submission.hub.no_sheets_yet_named", sheet: "Homework 1")
        )
      end

      it "dims a sheet from before points existed" do
        create(:assignment, :expired, :without_assessment, lecture: lecture,
                                                           title: "Blatt 4")

        get lecture_submissions_path(lecture)

        expect(response.body).to include(I18n.t("submission.hub.old_style"))
        expect(response.body).to include(I18n.t("submission.hub.no_points"))
      end

      it "names the date the files go" do
        sheet(title: "Homework 8")

        get lecture_submissions_path(lecture)

        expect(response.body).to include(
          I18n.t("submission.hub.deletion_notice",
                 date: I18n.l(lecture.submission_deletion_date, format: :long))
        )
      end

      # The loader answers in a fixed number of queries; a row or a fold that
      # reaches past what it was handed would put that back, once per sheet.
      it "does not go back to the database for another row" do
        # The first request of the process pays for the schema and for devise
        # writing the sign-in down, and neither has to do with the rows.
        queries_for_sheets(1)

        expect(queries_for_sheets(12)).to eq(queries_for_sheets(2))
      end

      def queries_for_sheets(count)
        other = create(:lecture, :released_for_all)
        user.lectures << other
        group = create(:tutorial, lecture: other)
        create(:tutorial_membership, tutorial: group, user: user)
        partner = create(:confirmed_user)
        count.times do |index|
          assignment = create(:assignment, :expired, lecture: other,
                                                     title: "Homework #{index + 1}",
                                                     expired_since: (index + 1).weeks)
          create(:assessment_task, assessment: assignment.assessment, max_points: 4)
          # Files and a partner, so the fold has every association it reads.
          submission = create(:submission, :with_manuscript, :with_correction,
                              assignment: assignment, tutorial: group)
          submission.users << user
          submission.users << partner
          mark(assignment, [1.5])
        end

        count_queries { get(lecture_submissions_path(other)) }
      end

      def count_queries
        count = 0
        subscription = ActiveSupport::Notifications
                       .subscribe("sql.active_record") do |*, payload|
          count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION|CACHE/)
        end
        yield
        count
      ensure
        ActiveSupport::Notifications.unsubscribe(subscription)
      end

      it "carries the points per problem into the fold" do
        mark(sheet(title: "Homework 8"), [1.5, 2])

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(I18n.t("submission.hub.fold.tasks_heading"))
        expect(response.body).to include(
          I18n.t("submission.hub.points_reader", points: "1.5", max: "4")
        )
      end

      # Without the fold a student cannot reach their own PDFs at all once the
      # deadline has passed.
      it "puts both files back within reach" do
        marked = sheet(title: "Homework 8")
        submission = hand_in(marked, correction: true)
        mark(marked, [1.5, 2])

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(show_submission_manuscript_path(submission))
        expect(response.body).to include(show_correction_path(submission))
      end

      # A sheet that can still be handed in has its card above the list. A row
      # for it as well would tell it twice, and a row cannot be handed in.
      it "leaves every sheet that is still open out of the list" do
        sheet(title: "Homework 8")
        create(:assignment, lecture: lecture, title: "Homework 9",
                            deadline: 1.week.from_now)
        create(:assignment, lecture: lecture, title: "Homework 10",
                            deadline: 3.weeks.from_now)

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(I18n.t("submission.hub.sheet_count", count: 1))
      end

      # Handing in early is a thing people do, and the old page allowed it.
      it "gives a sheet due later a card of its own" do
        create(:assignment, lecture: lecture, title: "Homework 9",
                            deadline: 1.week.from_now)
        create(:assignment, lecture: lecture, title: "Homework 10",
                            deadline: 3.weeks.from_now)

        get lecture_submissions_path(lecture)

        expect(response.body.scan("submissionArea").size).to eq(2)
        expect(response.body).to include("Homework 10")
      end
    end
  end
end
