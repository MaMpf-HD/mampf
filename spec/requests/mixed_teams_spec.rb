require "rails_helper"

# A team whose members sit in different tutorials: the system files it with
# the tutorial that has fewer hand-ins, its tutor may hand it over, and the
# other tutor reads along.
RSpec.describe("Teams across tutorials", type: :request) do
  include ActiveSupport::Testing::TimeHelpers

  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) do
    create(:assignment, lecture: lecture, deadline: 1.week.from_now)
  end
  let(:tutor_x) { create(:confirmed_user) }
  let(:tutor_y) { create(:confirmed_user) }
  let(:tutorial_x) { create(:tutorial, lecture: lecture, title: "Monday") }
  let(:tutorial_y) { create(:tutorial, lecture: lecture, title: "Tuesday") }
  let(:anna) { student_in(tutorial_x) }
  let(:ben) { student_in(tutorial_y) }

  def student_in(tutorial)
    create(:confirmed_user).tap do |user|
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: tutorial, user: user)
    end
  end

  def hand_in(tutorial, *users)
    create(:submission, :with_manuscript, assignment: assignment,
                                          tutorial: tutorial).tap do |submission|
      submission.users << users
      users.each do |user|
        create(:assessment_participation, assessment: assignment.assessment,
                                          user: user, tutorial: tutorial,
                                          submitted_at: 1.hour.ago)
      end
    end
  end

  def join(submission, user)
    sign_in(user)
    post(join_submission_path, params: {
           join: { code: submission.token, assignment_id: assignment.id }
         })
  end

  def row_tutorials(submission)
    assignment.assessment.assessment_participations
              .where(user: submission.users).distinct.pluck(:tutorial_id)
  end

  before do
    create(:tutor_tutorial_join, tutorial: tutorial_x, tutor: tutor_x)
    create(:tutor_tutorial_join, tutorial: tutorial_y, tutor: tutor_y)
  end

  describe "joining" do
    it "files the team with the tutorial that has fewer hand-ins" do
      hand_in(tutorial_x, student_in(tutorial_x))
      submission = hand_in(tutorial_x, anna)

      join(submission, ben)

      expect(submission.reload.tutorial).to eq(tutorial_y)
      expect(row_tutorials(submission)).to eq([tutorial_y.id])
    end

    it "gives a tie to the tutorial created first, not to whoever uploaded" do
      submission = hand_in(tutorial_y, ben)

      join(submission, anna)

      expect(submission.reload.tutorial).to eq(tutorial_x)
    end

    it "keeps a team that is already mixed where a tutor handed it" do
      hand_in(tutorial_y, student_in(tutorial_y))
      submission = hand_in(tutorial_y, anna, ben)

      join(submission, student_in(tutorial_x))

      expect(submission.reload.tutorial).to eq(tutorial_y)
    end

    it "leaves a team of one tutorial where it is" do
      submission = hand_in(tutorial_x, anna)

      join(submission, student_in(tutorial_x))

      expect(submission.reload.tutorial).to eq(tutorial_x)
    end
  end

  describe "leaving" do
    it "takes the team back to the tutorial its remaining members sit in" do
      submission = hand_in(tutorial_y, anna, ben)

      sign_in ben
      delete leave_submission_path(submission)

      expect(submission.reload.tutorial).to eq(tutorial_x)
      expect(row_tutorials(submission)).to eq([tutorial_x.id])
    end

    it "leaves a corrected team with the tutor who corrected it" do
      submission = hand_in(tutorial_y, anna, ben)
      submission.update!(correction: File.open("#{SPEC_FILES}/manuscript.pdf", "rb"))

      sign_in ben
      delete leave_submission_path(submission)

      expect(submission.reload.tutorial).to eq(tutorial_y)
    end
  end

  describe "PATCH /submissions/:id/hand_over" do
    let(:submission) { hand_in(tutorial_x, anna, ben) }

    def hand_over(to:, by:)
      sign_in(by)
      patch(hand_over_submission_path(submission),
            params: { tutorial_id: to.id, grading_scope_type: "tutorial" },
            as: :turbo_stream)
    end

    it "moves the team and its rows to the other tutorial" do
      hand_over(to: tutorial_y, by: tutor_x)

      expect(response).to have_http_status(:ok)
      expect(submission.reload.tutorial).to eq(tutorial_y)
      expect(row_tutorials(submission)).to eq([tutorial_y.id])
      expect(response.body).to include(I18n.t("submission.handed_over",
                                              tutorial: tutorial_y.title))
    end

    it "is not the other tutor's to take" do
      hand_over(to: tutorial_y, by: tutor_y)

      expect(response).to redirect_to(root_url)
      expect(submission.reload.tutorial).to eq(tutorial_x)
    end

    it "goes only to a tutorial one of the members sits in" do
      elsewhere = create(:tutorial, lecture: lecture)

      hand_over(to: elsewhere, by: tutor_x)

      expect(response).to have_http_status(:unprocessable_content)
      expect(submission.reload.tutorial).to eq(tutorial_x)
    end

    it "stays once there are points" do
      submission
      travel_to(assignment.deadline + 1.day)
      task = create(:assessment_task, assessment: assignment.assessment, max_points: 10)
      row = assignment.assessment.assessment_participations.find_by(user: anna)
      create(:assessment_task_point, task: task, assessment_participation: row, points: 4)
      row.reload.update!(status: :reviewed, graded_at: Time.current)

      hand_over(to: tutorial_y, by: tutor_x)

      expect(response).to have_http_status(:unprocessable_content)
      expect(submission.reload.tutorial).to eq(tutorial_x)
    end
  end

  describe "the other tutor" do
    let(:submission) { hand_in(tutorial_x, anna, ben) }

    it "reads the hand-in and the correction" do
      submission.update!(correction: File.open("#{SPEC_FILES}/manuscript.pdf", "rb"))
      sign_in tutor_y

      get show_submission_manuscript_path(submission)
      expect(response).to have_http_status(:ok)

      get show_correction_path(submission)
      expect(response).to have_http_status(:ok)
    end

    it "is the only tutor besides the marking one who does" do
      outsider = create(:confirmed_user)
      create(:tutor_tutorial_join, tutorial: create(:tutorial, lecture: lecture),
                                   tutor: outsider)
      sign_in outsider

      get show_submission_manuscript_path(submission)

      expect(response).to redirect_to(root_url)
    end
  end

  describe "a lecture that keeps teams within one tutorial" do
    before { lecture.update!(cross_tutorial_teams: false) }

    it "refuses a join from another tutorial and says why" do
      submission = hand_in(tutorial_x, anna)

      join(submission, ben)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(
        ERB::Util.html_escape(I18n.t("activerecord.errors.models.user_submission_join" \
                                     ".other_tutorial").squish)
      )
      expect(submission.reload.users).to eq([anna])
    end

    it "takes a join from the same tutorial" do
      submission = hand_in(tutorial_x, anna)
      partner = student_in(tutorial_x)

      join(submission, partner)

      expect(submission.reload.users).to contain_exactly(anna, partner)
    end

    # The two teamed up before the lecture kept teams within a tutorial.
    it "does not offer or invite a past partner from another tutorial" do
      lecture.update!(cross_tutorial_teams: true)
      earlier = create(:assignment, :expired, lecture: lecture, title: "Homework 0")
      create(:submission, :with_manuscript, assignment: earlier, tutorial: tutorial_x,
                                            users: [anna, ben])
      lecture.update!(cross_tutorial_teams: false)
      submission = hand_in(tutorial_x, anna)
      sign_in anna

      get enter_submission_invitees_path(submission)
      expect(response.body).not_to include(ben.tutorial_name)

      post invite_to_submission_path(submission),
           params: { submission: { invitee_ids: [ben.id] } }
      expect(submission.reload.invited_user_ids).to be_empty
    end
  end
end
