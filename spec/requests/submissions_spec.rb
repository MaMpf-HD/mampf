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
        expect(response.body)
          .to include(I18n.t("submission.hub.card.nothing_due"))
        expect(response.body)
          .to include(I18n.t("submission.hub.card.nothing_scheduled"))
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
        soon = create(:assignment, lecture: lecture, title: "Homework 9",
                                   deadline: 1.week.from_now)
        later = create(:assignment, lecture: lecture, title: "Homework 10",
                                    deadline: 3.weeks.from_now)

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(SubmissionCardComponent.frame_id(soon))
        expect(response.body)
          .to include(SubmissionCardComponent.frame_id(later))
      end
    end
  end

  # Every student action answers with the card's own Turbo frame. What matters
  # per action is that the answer has a body at all - a frame response that
  # renders nothing is a 204, and the page then sits there looking successful.
  describe "the card's actions" do
    let(:assignment) do
      create(:assignment, lecture: lecture, title: "Homework 1",
                          accepted_file_type: ".pdf")
    end

    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      user.lectures << lecture
    end

    def frame_id(for_assignment = assignment)
      SubmissionCardComponent.frame_id(for_assignment)
    end

    def hand_in(for_assignment = assignment, users: [user])
      submission = create(:submission, :with_manuscript,
                          assignment: for_assignment, tutorial: tutorial)
      users.each { |member| submission.users << member }
      submission
    end

    describe "opening and closing the form" do
      it "answers new with the form inside the card's frame" do
        get new_submission_path(assignment_id: assignment.id)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
        expect(response.body).to include(I18n.t("basics.submission"))
      end

      it "answers edit with the form for the sheet in hand" do
        submission = hand_in

        get edit_submission_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
      end

      it "hands the card back when the reader cancels" do
        submission = hand_in

        get cancel_edit_submission_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
        expect(response.body).to include("Homework 1")
      end
    end

    # The file itself goes through the upload endpoint, which signs a scan and an
    # intent before the form ever sees it; what is checked here is the frame
    # round-trip around it.
    describe "handing in" do
      it "answers with the card, which now carries a team and a code" do
        post submissions_path, params: {
          submission: { assignment_id: assignment.id, invitee_ids: [""],
                        tutorial_id: tutorial.id, manuscript: "" }
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
        expect(response.body).to include(I18n.t("submission.hub.card.code"))
      end

      # The message belongs beside the field, not in an alert next to a card
      # that still shows the old state. A group of another lecture only reaches
      # the model where the lecture does not assign groups itself - where it
      # does, the controller picks the group and the field is not even shown.
      it "answers a refused group with the form and the reason" do
        free = create(:lecture, :released_for_all)
        create(:tutorial, lecture: free)
        user.lectures << free
        free_assignment = create(:assignment, lecture: free, title: "Sheet")
        elsewhere = create(:tutorial, lecture: create(:lecture))

        post submissions_path, params: {
          submission: { assignment_id: free_assignment.id, invitee_ids: [""],
                        tutorial_id: elsewhere.id, manuscript: "" }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body)
          .to include(SubmissionCardComponent.frame_id(free_assignment))
        expect(response.body).to include("submission-tutorial-error")
        expect(response.body)
          .not_to include(I18n.t("submission.hub.card.replace"))
      end
    end

    describe "leaving and deleting" do
      it "answers a delete with the card back to nothing handed in" do
        submission = hand_in

        delete submission_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(I18n.t("submission.hub.chips.nothing_handed_in"))
      end

      it "answers a leave with the card back to nothing handed in" do
        partner = create(:confirmed_user)
        submission = hand_in(users: [user, partner])

        delete leave_submission_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(I18n.t("submission.hub.chips.nothing_handed_in"))
      end

      # Leaving a team of one is a delete, and that is a different button.
      it "refuses to let the last person leave, and says so on the card" do
        submission = hand_in

        delete leave_submission_path(submission)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body)
          .to include(I18n.t("submission.no_partners_no_leave"))
      end
    end

    # The gate is the ability, not the controller: `SubmissionAbility` allows
    # these actions only while `Submission#not_updatable?` is false, and once the
    # grace period is over that is what a closed sheet is.
    describe "once the sheet is out of the reader's hands" do
      let(:closed_assignment) do
        create(:assignment, :expired, lecture: lecture, title: "Homework 0",
                                      accepted_file_type: ".pdf")
      end

      it "refuses an edit" do
        submission = hand_in(closed_assignment)

        patch submission_path(submission), params: {
          submission: { detach_user_manuscript: "true" }
        }

        expect(response).to redirect_to(root_url)
        expect(submission.reload.manuscript).to be_present
      end

      it "refuses a delete" do
        submission = hand_in(closed_assignment)

        delete submission_path(submission)

        expect(response).to redirect_to(root_url)
        expect(Submission.exists?(submission.id)).to be(true)
      end
    end

    describe "the team" do
      it "answers a new code with the card carrying it" do
        submission = hand_in
        old_code = submission.token

        patch refresh_submission_token_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(submission.reload.token)
        expect(response.body).not_to include(old_code)
      end

      it "answers a wrong code with the form and the reason" do
        post join_submission_path, params: {
          join: { code: "NOPE42", assignment_id: assignment.id }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(
          I18n.t("submission.invalid_code_for_assignment",
                 assignment: assignment.title)
        )
      end

      it "answers a good code with the card naming the team" do
        partner = create(:confirmed_user, name_in_tutorials: "Ada")
        create(:tutorial_membership, tutorial: tutorial, user: partner)
        partner.lectures << lecture
        submission = hand_in(users: [partner])

        post join_submission_path, params: {
          join: { code: submission.token, assignment_id: assignment.id }
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Ada")
      end

      # Inviting by name is offered for people the reader has handed in with
      # before - the first team-up goes through the code.
      it "offers a past partner when inviting" do
        partner = create(:confirmed_user, name_in_tutorials: "Ada")
        earlier = create(:assignment, :expired, lecture: lecture,
                                                title: "Homework 0")
        hand_in(earlier, users: [user, partner])
        submission = hand_in

        get enter_submission_invitees_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
        expect(response.body).to include("Ada")
      end

      it "answers an invitation with the card naming who was invited" do
        partner = create(:confirmed_user, name_in_tutorials: "Ada")
        earlier = create(:assignment, :expired, lecture: lecture,
                                                title: "Homework 0")
        hand_in(earlier, users: [user, partner])
        submission = hand_in

        post invite_to_submission_path(submission),
             params: { submission: { invitee_ids: [partner.id] } }

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Ada")
      end
    end

    # Handing in makes a sheet count among the points still being marked, so it
    # changes the standing as well as the card. Two places, and a frame carries
    # one - hence a stream with two targets.
    describe "the two places a hand-in changes" do
      it "answers a hand-in with both the card and the standing" do
        post submissions_path, as: :turbo_stream, params: {
          submission: { assignment_id: assignment.id, invitee_ids: [""],
                        tutorial_id: tutorial.id, manuscript: "" }
        }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        assert_turbo_stream(action: :replace, target: frame_id)
        assert_turbo_stream(action: :replace, target: StandingComponent::TARGET)
      end

      it "answers a delete with both, so the pending points go back" do
        submission = hand_in

        delete submission_path(submission), as: :turbo_stream

        assert_turbo_stream(action: :replace, target: frame_id)
        assert_turbo_stream(action: :replace, target: StandingComponent::TARGET)
      end

      it "answers a join with both" do
        partner = create(:confirmed_user)
        submission = hand_in(users: [partner])

        post join_submission_path, as: :turbo_stream, params: {
          join: { code: submission.token, assignment_id: assignment.id }
        }

        assert_turbo_stream(action: :replace, target: frame_id)
        assert_turbo_stream(action: :replace, target: StandingComponent::TARGET)
      end

      it "answers a leave with both" do
        partner = create(:confirmed_user)
        submission = hand_in(users: [user, partner])

        delete leave_submission_path(submission), as: :turbo_stream

        assert_turbo_stream(action: :replace, target: frame_id)
        assert_turbo_stream(action: :replace, target: StandingComponent::TARGET)
      end

      # Opening and closing a form changes one place only, and a stream that
      # rewrites the standing for nothing is a second thing to keep in step.
      it "answers a cancelled form with the card alone" do
        submission = hand_in

        get cancel_edit_submission_path(submission)

        expect(response.media_type).to eq("text/html")
        expect(response.body).to include(frame_id)
        expect(response.body).not_to include(StandingComponent::TARGET)
      end
    end

    # Deleted in another tab: there is no card left to put a message in, so the
    # frame says so rather than navigating itself somewhere unexpected.
    it "answers for a submission that is gone with a frame that says so" do
      submission = hand_in
      submission.destroy

      get edit_submission_path(submission)

      expect(response).to have_http_status(:gone)
      expect(response.body).to include(I18n.t("controllers.no_submission"))
    end
  end
end
