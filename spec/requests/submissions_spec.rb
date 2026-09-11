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

    # No `invitee_ids`: the select is empty until somebody is picked, and then
    # the browser sends no field at all. The record used to be saved and the
    # answer thrown away - so the response is the part worth checking.
    it "lets a student enrolled in the lecture create a submission" do
      user.lectures << lecture
      create(:tutorial_membership, tutorial: tutorial, user: user)

      expect { post(submissions_path, params: create_params) }
        .to change(Submission, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.body)
        .to include(SubmissionCardComponent.frame_id(assignment))
    end

    # The hand-in goes to the group the reader sits in - that is who marks it
    # and how it reaches the gradebook - so being enrolled is not enough.
    it "refuses somebody who sits in no group" do
      user.lectures << lecture

      expect { post(submissions_path, params: create_params) }
        .not_to change(Submission, :count)

      expect(response).to redirect_to(start_path)
      follow_redirect!
      expect(flash[:alert]).to eq(I18n.t("submission.tutorial_not_assigned"))
    end

    # Deleted between the form and the save. It used to fall over asking a
    # lecture that was not there for a seat; the frame says what happened.
    it "answers a sheet deleted in the meantime with the frame that says so" do
      user.lectures << lecture
      create(:tutorial_membership, tutorial: tutorial, user: user)
      gone = create(:assignment, lecture: lecture, accepted_file_type: ".pdf")
      gone.destroy!

      post(submissions_path, params: { submission: { assignment_id: gone.id,
                                                     manuscript: "" } })

      expect(response).to have_http_status(:gone)
      expect(response.body).to include(I18n.t("controllers.no_assignment"))
    end

    it "files it under the group the reader sits in, not one they name" do
      user.lectures << lecture
      create(:tutorial_membership, tutorial: tutorial, user: user)
      elsewhere = create(:tutorial, lecture: lecture)

      post(submissions_path,
           params: { submission: { assignment_id: assignment.id,
                                   tutorial_id: elsewhere.id,
                                   manuscript: "" } })

      expect(Submission.last.tutorial).to eq(tutorial)
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
        expect { post(submissions_path, params: create_params_no_tutorial) }
          .to change(Submission, :count).by(1)

        expect(Submission.last.tutorial).to eq(tutorial)
        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(SubmissionCardComponent.frame_id(assignment))
      end
    end
  end

  # `SubmissionAbility` grants these to anybody logged in: they carry no
  # submission of their own to hang a rule on, only a sheet. So one
  # before_action gates them all with the rule handing in uses, and the group is
  # walked here on purpose - four gates is how the fifth gets forgotten.
  describe "the actions that take a sheet, asked by somebody not in the lecture" do
    let(:submission) do
      create(:submission, assignment: assignment, tutorial: tutorial)
        .tap { |record| record.users << create(:confirmed_user) }
    end

    it "turns a stranger away from the hand-in form" do
      get new_submission_path(assignment_id: assignment.id)

      expect(response).to redirect_to(root_url)
    end

    # This one named the sheet of a lecture the reader has nothing to do with.
    it "turns a stranger away from the code form" do
      get enter_submission_code_path(assignment_id: assignment.id)

      expect(response).to redirect_to(root_url)
      expect(response.body).not_to include(assignment.title)
    end

    it "turns a stranger away from the cancelled hand-in" do
      get cancel_new_submission_path(assignment_id: assignment.id)

      expect(response).to redirect_to(root_url)
    end

    # Reached with a submission rather than a sheet, and it answers with the
    # card - which is the sheet named again.
    it "turns a stranger away from the cancelled edit" do
      get cancel_edit_submission_path(submission)

      expect(response).to redirect_to(root_url)
      expect(response.body).not_to include(assignment.title)
    end

    it "turns a stranger away from joining" do
      post join_submission_path, params: {
        join: { code: submission.token, assignment_id: assignment.id }
      }

      expect(response).to redirect_to(root_url)
    end

    # The way in that was a 500: the sheet was dereferenced before anybody
    # asked whether it exists.
    it "answers a join for a sheet that is gone with the frame that says so" do
      gone = create(:assignment, lecture: lecture)
      id = gone.id
      gone.destroy

      post join_submission_path, params: { join: { code: "whatever",
                                                   assignment_id: id } }

      expect(response).to have_http_status(:gone)
      expect(response.body).to include(I18n.t("controllers.no_assignment"))
    end

    # Turbo drops a response whose frame is not the one that asked, and drops it
    # silently: the button would look broken while the log says 410.
    it "answers inside the frame that asked" do
      gone = create(:assignment, lecture: lecture)
      id = gone.id
      gone.destroy

      post join_submission_path,
           params: { join: { code: "whatever", assignment_id: id } },
           headers: { "Turbo-Frame" => "submission_card_assignment_#{id}" }

      expect(response.body).to include("id=\"submission_card_assignment_#{id}\"")
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
      expect(response.body)
        .to include(I18n.t("submission.hub.card.no_seat_yet"))
    end

    # A sheet from before the groups were kept here - one without a pointbook -
    # refuses just the same; only the sentence differs.
    it "is refused the same way on a sheet from before the groups" do
      assignment.assessment.destroy

      get lecture_submissions_path(lecture)

      expect(response.body).not_to include("create-submission")
      expect(response.body)
        .to include(I18n.t("submission.hub.card.before_groups"))
    end

    # The form names the group instead of offering a choice, and there is none
    # to name. It used to reach the view and blow up there; now it gives the
    # refusal the save gives, and the reader is told what is missing.
    it "is told what is missing rather than crashing on the form" do
      get new_submission_path(assignment_id: assignment.id)

      expect(response).to redirect_to(start_path)
      follow_redirect!
      expect(flash[:alert]).to eq(I18n.t("submission.tutorial_not_assigned"))
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

      # The work stays where it was handed in, whatever became of the reader's
      # seat since: it is the tutor who has it who marks it.
      it "leaves the submission with the group it was handed in to" do
        patch submission_path(submission, format: :js),
              params: { submission: { manuscript: "" } }

        expect(submission.reload.tutorial).to eq(tutorial)
      end

      # The card offers to replace the file; the form behind that offer must
      # open. A seat is what a new hand-in needs, not what replacing a file on
      # one that exists needs.
      it "still opens the form to replace the file without a seat" do
        get edit_submission_path(submission)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(SubmissionCardComponent.frame_id(assignment))
      end

      # The group named on the form is the one the work is filed under - the
      # tutor who has it - not the seat the reader happens to have now.
      it "names the group the work is filed under, not the reader's seat" do
        create(:tutorial_membership, tutorial: other_tutorial, user: user)

        get edit_submission_path(submission)

        expect(response.body).to include(CGI.escapeHTML(tutorial.title))
        expect(response.body).not_to include(CGI.escapeHTML(other_tutorial.title))
      end
    end

    context "roster-eligible lecture, student enrolled" do
      before do
        create(:lecture_membership, lecture: lecture, user: user)
        create(:tutorial_membership, tutorial: tutorial, user: user)
      end

      it "updates the submission, keeping the group it was handed in to" do
        patch submission_path(submission, format: :js),
              params: update_params(tutorial_id: other_tutorial.id)

        expect(submission.reload.tutorial).to eq(tutorial)
      end
    end
  end

  # A rejected hand-in waits for nothing any more. Until the gradebook is told,
  # it stays among the points still being marked - and those are taken out of
  # the base the student is measured against, so refusing a sheet would raise
  # her percentage instead of leaving it where it was.
  describe "PATCH /submissions/:id/reject" do
    let(:tutor) { create(:confirmed_user) }
    let(:due_points) { StudentPerformance::DuePoints.new(lecture: lecture) }

    def sheet_worth(points, title:)
      created = create(:assignment, :expired, lecture: lecture, title: title)
      create(:assessment_task, assessment: created.assessment,
                               max_points: points)
      created
    end

    def hand_in(for_assignment)
      submission = create(:submission, :with_manuscript,
                          assignment: for_assignment, tutorial: tutorial)
      submission.users << user
      create(:assessment_participation, assessment: for_assignment.assessment,
                                        user: user, submitted_at: 2.days.ago)
      submission
    end

    before do
      create(:tutor_tutorial_join, tutorial: tutorial, tutor: tutor)
      create(:lecture_membership, lecture: lecture, user: user)
      marked = sheet_worth(20, title: "Homework 1")
      participation = create(:assessment_participation,
                             assessment: marked.assessment, user: user,
                             submitted_at: 3.days.ago)
      create(:assessment_task_point, task: marked.assessment.tasks.first,
                                     assessment_participation: participation,
                                     points: 20)
      participation.reload.update!(status: :reviewed, graded_at: 1.day.ago)
    end

    it "leaves the refused sheet in what the student is measured against" do
      submission = hand_in(sheet_worth(20, title: "Homework 2"))

      sign_in tutor
      patch reject_submission_path(submission), as: :turbo_stream

      record = lecture.student_performance_records.find_by(user_id: user.id)

      expect(due_points.marked_max_for(user.id)).to eq(40)
      expect(due_points.marked_percentage_for(record)).to eq(50)
    end

    # And back again: a hand-in refused and then accepted after all is waiting
    # to be marked, so its points leave the base a second time.
    it "puts it back in the queue once the tutor accepts after all" do
      submission = hand_in(sheet_worth(20, title: "Homework 2"))

      sign_in tutor
      patch reject_submission_path(submission), as: :turbo_stream
      patch accept_submission_path(submission), as: :turbo_stream

      expect(due_points.marked_max_for(user.id)).to eq(20)
      expect(due_points.pending_count_for(user.id)).to eq(1)
    end
  end

  describe "GET /lectures/:id/submissions" do
    let!(:assignments) { create_list(:assignment, 5, lecture: lecture, accepted_file_type: ".pdf") }

    before do
      create(:tutorial_membership, tutorial: tutorial, user: user)
      user.lectures << lecture
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

  # Sighted readers get the lecture from the navbar; somebody moving by heading
  # gets nothing above the sheet that happens to be due.
  describe "the page's own heading" do
    it "names the page and the lecture, for readers who navigate by heading" do
      user = create(:confirmed_user)
      course = create(:course, title: "All the King's Men")
      lecture = create(:lecture, :released_for_all, course: course)
      tutorial = create(:tutorial, lecture: lecture)
      create(:tutorial_membership, tutorial: tutorial, user: user)
      user.lectures << lecture
      sign_in user

      get lecture_submissions_path(lecture)

      # Through the parser, not the raw body: a title with an apostrophe
      # arrives escaped, and the comparison is about the words.
      heading = Nokogiri::HTML(response.body).at_css("h1")
      expect(heading.text.squish).to eq(
        I18n.t("submission.hub.page_title", lecture: lecture.title_for_viewers)
      )
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

      # A lecture without groups used to send everybody back to the start page,
      # which took the archive with it - last term's hand-ins and corrections
      # are read here too. The page opens and says what is missing instead.
      it "opens a lecture without tutorials and says so" do
        without_tutorials = create(:lecture, :released_for_all)
        create(:assignment, lecture: without_tutorials, title: "Sheet 1")
        user.lectures << without_tutorials

        get(lecture_submissions_path(without_tutorials))

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(I18n.t("submission.hub.card.no_tutorials_yet"))
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

      # Every sheet is worth nothing between being created and having its
      # problems set up, and the demo has no sheet in that window - so this is
      # the only place the page is ever seen in it.
      it "leaves a sheet whose problems are not set up yet without a number" do
        sheet(title: "Homework 7", max_points: [])

        get lecture_submissions_path(lecture)

        expect(response.body).to include("Homework 7")
        expect(response.body).to include(I18n.t("submission.hub.notes.missed"))
        expect(response.body)
          .to include(I18n.t("submission.hub.fold.no_points.no_tasks"))
        expect(response.body).not_to include(
          I18n.t("submission.hub.points_reader", points: "0", max: "0")
        )
      end

      # A problem may be set at 0 and `Assessment::TaskPoint` puts no ceiling on
      # what a tutor may award against it, so a sheet can carry points with no
      # scale to read them on. Both halves of the page have to say so.
      it "shows points on a sheet with no scale, and no denominator anywhere" do
        mark(sheet(title: "Homework 6", max_points: [0]), [2])

        get lecture_submissions_path(lecture)

        expect(response.body).to include(
          I18n.t("submission.hub.points_reader_no_max", points: "2")
        )
        expect(response.body).not_to include(
          I18n.t("submission.hub.points_reader", points: "2", max: "0")
        )
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

      # A card asks for more than a row does - the team, the group it hands in
      # to, who has been invited_users - and until this example existed the assurance
      # covered only sheets that were already closed.
      it "does not go back to the database for another card" do
        queries_for_sheets(1)

        expect(queries_for_sheets(6, open: 6)).to eq(queries_for_sheets(1, open: 1))
      end

      def queries_for_sheets(count, open: 0)
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
        open.times { |index| open_sheet_for(other, group, partner, index) }

        count_queries { get(lecture_submissions_path(other)) }
      end

      # Everything a card reads: a file, a team, a group with a tutor on it, and
      # somebody invited_users who has not joined.
      def open_sheet_for(lecture_record, group, partner, index)
        assignment = create(:assignment, lecture: lecture_record,
                                         title: "Sheet #{index + 1}",
                                         deadline: (index + 1).weeks.from_now)
        create(:tutor_tutorial_join, tutorial: group, tutor: create(:confirmed_user))
        submission = create(:submission, :with_manuscript,
                            assignment: assignment, tutorial: group,
                            invited_user_ids: [partner.id])
        submission.users << user
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

      # `Sheet#state` calls a rejected sheet rejected before it looks at the
      # clock, and "still open" asked the clock alone: inside the grace period
      # the sheet got a card, and the card has no badge, no note and no number
      # for this state. The row has all three.
      it "puts a rejected sheet in the list, where it can say what happened" do
        lecture.update(submission_grace_period: 60)
        rejected = create(:assignment, :expired, lecture: lecture,
                                                 title: "Homework 4",
                                                 expired_since: 10.minutes)
        create(:assessment_task, assessment: rejected.assessment, max_points: 8)
        hand_in(rejected).update(accepted: false)

        get lecture_submissions_path(lecture)

        expect(response.body).to include(I18n.t("submission.hub.notes.rejected"))
        expect(response.body).to include(
          I18n.t("submission.hub.points_reader", points: "0", max: "8")
        )
        expect(response.body)
          .not_to include(SubmissionCardComponent.frame_id(rejected))
      end

      # The other way round, so the rule does not reach too far: while nobody
      # has decided, the sheet is still the reader's to look at, and the card
      # is where that is said.
      it "keeps a late sheet nobody has decided on as a card" do
        lecture.update(submission_grace_period: 60)
        undecided = create(:assignment, :expired, lecture: lecture,
                                                  title: "Homework 5",
                                                  expired_since: 10.minutes)
        hand_in(undecided)

        get lecture_submissions_path(lecture)

        expect(response.body)
          .to include(SubmissionCardComponent.frame_id(undecided))
        expect(response.body)
          .to include(I18n.t("submission.hub.chips.tutor_decides"))
      end

      # The number the block leads with is the reader's standing, and it used to
      # be taken of every sheet the lecture had set up: two sheets marked in
      # full, a third still running, and the page said 47 %.
      it "measures the reader against the sheets that have been marked" do
        create(:lecture_membership, lecture: lecture, user: user)
        create(:student_performance_rule, :active, :with_percentage,
               lecture: lecture, min_percentage: 50)
        mark(sheet(title: "Homework 1", max_points: [8]), [8])
        mark(sheet(title: "Homework 2", max_points: [10]), [10])
        running = create(:assignment, lecture: lecture, title: "Homework 3",
                                      deadline: 1.week.from_now)
        create(:assessment_task, assessment: running.assessment,
                                 max_points: 20)

        get lecture_submissions_path(lecture)

        expect(response.body).to include(
          I18n.t("submission.hub.standing.of_marked", max: "18")
        )
        expect(response.body).to include(
          I18n.t("submission.hub.standing.you_have_percent", percentage: "100")
        )
        expect(response.body).not_to include(
          I18n.t("submission.hub.standing.you_have_percent",
                 percentage: "47.37")
        )
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
          submission: { assignment_id: assignment.id,
                        tutorial_id: tutorial.id, manuscript: "" }
        }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(frame_id)
        expect(response.body).to include(I18n.t("submission.hub.card.code"))
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

      it "answers an invitation with the card naming who was invited_users" do
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

    # The ability already refuses an edit, a delete and a leave on a rejected
    # sheet. Joining was the way in that was left open, and it leads to a card
    # that offers nothing.
    describe "a rejected sheet in the grace period" do
      let(:rejected_assignment) do
        lecture.update(submission_grace_period: 60)
        create(:assignment, :expired, lecture: lecture, title: "Homework 2",
                                      accepted_file_type: ".pdf",
                                      expired_since: 10.minutes)
      end

      it "refuses a join by code and says why" do
        submission = hand_in(rejected_assignment,
                             users: [create(:confirmed_user)])
        submission.update(accepted: false)

        post join_submission_path, params: {
          join: { code: submission.token, assignment_id: rejected_assignment.id }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("submission.already_rejected"))
      end

      it "does not put the code on the card any more" do
        submission = hand_in(rejected_assignment)
        submission.update(accepted: false)

        get lecture_submissions_path(lecture)

        expect(response.body).not_to include(submission.token)
      end
    end

    # `clear_submitted_at` writes with `update_all`, which skips the callback
    # that keeps the materialized record honest. Everything downstream reads
    # that record - the performance table, the admission rule - so what is
    # checked here is that the record is put back in step.
    describe "the standing when a hand-in stops waiting to be marked" do
      # Something marked, so the block has a total to talk about.
      def a_marked_sheet
        # The roster membership is what the computation service counts by.
        create(:lecture_membership, lecture: lecture, user: user)
        closed = create(:assignment, :expired, lecture: lecture,
                                               title: "Homework 0")
        create(:assessment_task, assessment: closed.assessment, max_points: 4)
        marked = create(:assessment_participation, assessment: closed.assessment,
                                                   user: user,
                                                   submitted_at: 5.days.ago)
        create(:assessment_task_point,
               task: closed.assessment.tasks.first,
               assessment_participation: marked, points: 3)
        marked.reload.update!(status: :reviewed, graded_at: 4.days.ago)
      end

      # The sheet in hand is the one that is still open, because that is the
      # only kind a reader may still delete, leave or take a file out of.
      def waiting_beside_a_marked_sheet
        a_marked_sheet
        create(:assessment_task, assessment: assignment.assessment,
                                 max_points: 8)
        create(:assessment_participation, assessment: assignment.assessment,
                                          user: user, submitted_at: 2.days.ago)
        hand_in
      end

      def pending_points
        lecture.student_performance_records.find_by(user_id: user.id)
               .points_max_pending_materialized
      end

      it "stops counting the points of a hand-in the reader deleted" do
        submission = waiting_beside_a_marked_sheet

        expect { delete(submission_path(submission)) }
          .to change { pending_points }.from(8).to(0)
      end

      it "stops counting them when the reader leaves the team instead" do
        submission = waiting_beside_a_marked_sheet
        submission.users << create(:confirmed_user)

        expect { delete(leave_submission_path(submission)) }
          .to change { pending_points }.from(8).to(0)
      end

      it "stops counting them when the file is taken back out" do
        submission = waiting_beside_a_marked_sheet

        expect do
          patch(submission_path(submission), params: {
                  submission: { manuscript: "", detach_user_manuscript: "true" }
                })
        end.to change { pending_points }.from(8).to(0)
      end

      # A closed sheet is in the reckoning, so this is the one the page itself
      # talks about: the tutor decides, and the student's page answers.
      describe "and the sheet is closed, so the page names it" do
        def closed_sheet_waiting
          a_marked_sheet
          closed = create(:assignment, :expired, lecture: lecture,
                                                 title: "Homework 5",
                                                 accepted_file_type: ".pdf")
          create(:assessment_task, assessment: closed.assessment, max_points: 8)
          create(:assessment_participation, assessment: closed.assessment,
                                            user: user, submitted_at: 2.days.ago)
          hand_in(closed)
        end

        def waiting_sentence
          I18n.t("submission.hub.standing.awaiting_marks", count: 1,
                                                           points: "8",
                                                           max: "12")
        end

        # The tutor decides and hands the page back to the reader, which is
        # what makes both sides of it one example.
        def as_tutor
          tutor = create(:confirmed_user)
          create(:tutor_tutorial_join, tutorial: tutorial, tutor: tutor)
          sign_in(tutor)
          yield
          sign_in(user)
        end

        it "says how much is waiting and of what it is a part" do
          closed_sheet_waiting

          get lecture_submissions_path(lecture)

          expect(response.body).to include(waiting_sentence)
        end

        # A rejected hand-in waits for nothing, and until the gradebook is
        # told, its points stay among the ones being marked for good: nothing
        # else ever moves them.
        it "stops naming it once the tutor has rejected the hand-in" do
          submission = closed_sheet_waiting

          as_tutor { patch reject_submission_path(submission), as: :turbo_stream }
          get lecture_submissions_path(lecture)

          expect(response.body).to include(StandingComponent::TARGET)
          expect(response.body).not_to include(waiting_sentence)
        end

        # And back again: a hand-in refused and then accepted after all is
        # waiting to be marked, and the sheet must not read as one nobody
        # recorded.
        it "names it again once the tutor accepts after all" do
          submission = closed_sheet_waiting

          as_tutor do
            patch reject_submission_path(submission), as: :turbo_stream
            patch accept_submission_path(submission), as: :turbo_stream
          end
          get lecture_submissions_path(lecture)

          expect(response.body).to include(waiting_sentence)
        end
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

    # The sheet can go the same way as the submission, and used to answer with a
    # snippet of JavaScript that moved the whole page.
    it "answers for a sheet that is gone with a frame that says so" do
      gone = create(:assignment, lecture: lecture)
      id = gone.id
      gone.destroy

      get new_submission_path(assignment_id: id)

      expect(response).to have_http_status(:gone)
      expect(response.body).to include(I18n.t("controllers.no_assignment"))
    end
  end
end
