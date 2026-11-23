require "rails_helper"

RSpec.describe("The link in a submission invitation", type: :request) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:assignment) { create(:assignment, lecture: lecture, deadline: 1.week.from_now) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:inviter) { create(:confirmed_user, name_in_tutorials: "Ada Lovelace") }
  let(:invitee) { create(:confirmed_user) }
  let(:submission) do
    create(:submission, :with_manuscript, assignment: assignment, tutorial: tutorial,
                                          users: [inviter])
  end

  before do
    [inviter, invitee].each do |user|
      user.lectures << lecture
      create(:lecture_membership, lecture: lecture, user: user)
      create(:tutorial_membership, tutorial: tutorial, user: user)
    end
    sign_in invitee
  end

  it "asks before joining" do
    get redeem_submission_code_path(code: submission.token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ada Lovelace")
    expect(submission.reload.users).to eq([inviter])
  end

  it "joins once the reader confirms" do
    post redeem_submission_code_path, params: { code: submission.token }

    expect(response).to redirect_to(lecture_submissions_path(lecture))
    expect(submission.reload.users).to contain_exactly(inviter, invitee)
  end

  it "sends the reader back with the reason for a code that does not work" do
    get redeem_submission_code_path(code: "NOPE42")

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to include(I18n.t("submission.invalid_code"))
  end
end
