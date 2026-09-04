require "rails_helper"

RSpec.describe(SubmissionCardComponent, type: :component) do
  # The design is written in English, and so are its dates.
  around do |example|
    I18n.with_locale(:en) { example.run }
  end

  let(:lecture) { create(:lecture, :released_for_all, locale: "en") }
  let(:tutorial) { create(:tutorial, lecture: lecture, title: "Monday group") }
  let(:user) { create(:confirmed_user) }
  let(:assignment) do
    create(:assignment, lecture: lecture, title: "Homework 11",
                        deadline: 3.days.from_now)
  end

  # The card asks the roster helpers who is reading it; a component spec has no
  # session to answer from.
  before do
    user.lectures << lecture
    allow(vc_test_controller).to receive(:current_user).and_return(user)
  end

  def hand_in(traits = [:with_manuscript], **attrs)
    create(:submission, *traits, assignment: assignment, tutorial: tutorial,
                                 **attrs)
      .tap { |submission| submission.users << user }
  end

  def sheet_for(assignment_record = assignment)
    Assessment::SubmissionsHub::Loader
      .new(lecture: lecture, user: user).call
      .sheets.find { |sheet| sheet.assignment == assignment_record }
  end

  def render_card(**)
    render_inline(described_class.new(sheet: sheet_for, **))
    rendered_content
  end

  describe "a sheet nothing has been handed in for" do
    it "offers both ways to start and says how they work" do
      content = render_card

      expect(content).to include(I18n.t("submission.hub.card.hand_in"))
      expect(content).to include(I18n.t("submission.hub.card.join"))
      expect(content).to include(I18n.t("submission.hub.card.team_hint"))
      expect(content)
        .to include(I18n.t("submission.hub.chips.nothing_handed_in"))
    end

    # The problems are set up after the sheet is, so between the two there is
    # nothing to name - and "0 problems, 0 points" would name it anyway.
    it "says nothing about points before the problems are set up" do
      content = render_card

      expect(content).to include("PDF")
      expect(content).not_to include(
        I18n.t("submission.hub.card.worth", count: 0, points: "0")
      )
    end

    # What the card announces is the problems, not the scale: a problem that is
    # up before anybody has said what it is worth is still one to work on.
    it "counts problems that are up before they are worth anything" do
      create(:assessment_task, assessment: assignment.assessment, max_points: 0)

      content = render_card

      expect(content).to include(
        I18n.t("submission.hub.card.worth", count: 1, points: "0")
      )
    end

    it "names the sheet, its deadline and what it is worth" do
      book = assignment.assessment
      create(:assessment_task, assessment: book, max_points: 4)
      create(:assessment_task, assessment: book, max_points: 6)

      content = render_card

      expect(content).to include("Homework 11")
      expect(content).to include(
        I18n.l(assignment.deadline, format: :submission_deadline)
      )
      expect(content)
        .to include(I18n.t("submission.hub.card.worth", count: 2, points: "10"))
    end
  end

  describe "a sheet that has been handed in" do
    it "shows the file, and offers to replace it" do
      hand_in

      content = render_card

      expect(content).to include("manuscript.pdf")
      expect(content).to include(I18n.t("submission.hub.card.replace"))
      expect(content).to include(I18n.t("submission.hub.chips.handed_in"))
    end

    # The code is how a partner joins, so it is worth showing only while
    # somebody could still use it.
    it "shows the join code and the way to renew it" do
      submission = hand_in

      content = render_card

      expect(content).to include(submission.token)
      expect(content).to include(I18n.t("submission.hub.card.code"))
      expect(content).to include("#{submission.id}/refresh_token")
    end

    # A code that is passed on by voice or by hand: it can be copied, and it is
    # big enough to read off the screen when it cannot.
    it "offers to copy the code rather than only to read it" do
      submission = hand_in

      content = render_card

      expect(content).to include("data-clipboard-text-value=\"#{submission.token}\"")
      expect(content).to include(I18n.t("submission.hub.card.copy_code"))
      expect(content).to include("join-code")
    end

    # Renewing it locks out whoever already has it, so the question says that
    # rather than asking whether the reader is sure.
    it "asks before renewing the code, and says what renewing costs" do
      hand_in

      content = render_card

      expect(content).to include(
        "data-turbo-confirm=\"#{I18n.t("submission.hub.card.refresh_confirm")}\""
      )
    end

    # Both files can carry the same name, and then two links read alike. The
    # word in front of each says which one it is.
    it "tells the hand-in and the correction apart for a screen reader" do
      hand_in([:with_manuscript, :with_correction])

      content = render_card

      expect(content).to include(
        "aria-label=\"#{I18n.t("submission.hub.fold.handed_in_label")}: manuscript.pdf\""
      )
      expect(content).to include(
        "aria-label=\"#{I18n.t("submission.hub.fold.correction_label")}: manuscript.pdf\""
      )
    end

    it "offers to delete a hand-in the reader made alone, and says what that does" do
      hand_in

      content = render_card

      expect(content).to include(I18n.t("submission.hub.card.delete"))
      expect(content).not_to include(I18n.t("submission.hub.card.leave"))
      expect(content).to include(
        "data-turbo-confirm=\"#{I18n.t("submission.hub.card.delete_confirm")}\""
      )
    end

    # One submission, two people: leaving it is not deleting it.
    it "offers to leave a team of two, not to delete it" do
      partner = create(:confirmed_user, name_in_tutorials: "Ada")
      hand_in.users << partner

      content = render_card

      expect(content).to include(I18n.t("submission.hub.card.leave"))
      expect(content).not_to include(I18n.t("submission.hub.card.delete"))
      expect(content).to include("Ada")
      expect(content).to include(
        "data-turbo-confirm=\"#{I18n.t("submission.hub.card.leave_confirm")}\""
      )
    end

    it "offers to invite somebody the reader has handed in with before" do
      partner = create(:confirmed_user, name_in_tutorials: "Ada")
      hand_in

      content = render_card(partners: [partner])

      expect(content).to include(I18n.t("submission.hub.card.invite"))
    end

    # Inviting is only offered where there is somebody left to invite.
    it "says nothing about inviting when there is nobody to invite" do
      hand_in

      content = render_card(partners: [])

      expect(content).not_to include(I18n.t("submission.hub.card.invite"))
    end
  end

  describe "an invitation somebody sent" do
    it "names the inviter and offers one button to accept" do
      inviter = create(:confirmed_user, name_in_tutorials: "Ada")
      invite = create(:submission, assignment: assignment, tutorial: tutorial)
      invite.users << inviter

      content = render_card(invitations: [invite])

      expect(content).to include("Ada")
      expect(content).to include(I18n.t("submission.accept_invitation"))
      expect(content).to include(invite.token)
    end
  end

  # Leaving a team of one is a delete, and that is a different button.
  it "carries a refusal where the reader can see what it refers to" do
    hand_in

    content = render_card(error: "Not on your own")

    expect(content).to include("Not on your own")
    expect(content).to include("alert")
  end
end
