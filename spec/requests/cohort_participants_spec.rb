require "rails_helper"

RSpec.describe("CohortParticipants", type: :request) do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:tutor) { create(:confirmed_user) }
  let(:cohort) { create(:cohort, context: lecture, title: "Extra lessons") }
  let(:member) { create(:confirmed_user, first_name: "Ada", last_name: "Lovelace") }

  before do
    cohort.tutors << tutor
    create(:cohort_membership, cohort: cohort, user: member)
  end

  it "shows a cohort's tutor who is in it, with the mail to them" do
    sign_in tutor

    get lecture_cohort_participants_path(lecture)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ada Lovelace")
    expect(response.body).to include("value=\"cohort:#{cohort.id}\"")
  end

  it "gives the cohort's tutor an entry in the lecture's sidebar" do
    sign_in tutor

    get lecture_home_path(lecture)

    expect(response.body).to include(lecture_cohort_participants_path(lecture))
    expect(response.body).not_to include(lecture_submissions_path(lecture))
  end

  it "shows nobody else the list" do
    sign_in create(:confirmed_user)

    get lecture_cohort_participants_path(lecture)

    expect(response).to redirect_to(lecture_home_path(lecture))
  end
end
