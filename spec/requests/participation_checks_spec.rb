require "rails_helper"

RSpec.describe("ParticipationChecks", type: :request) do
  let(:term) { create(:term, :active) }
  let(:lecture) { create(:lecture, :released_for_all, term: term) }
  let(:student) { create(:confirmed_user) }

  before do
    create(:tutorial, lecture: lecture, skip_campaigns: true)
    lecture.add_user_to_roster!(student)
    sign_in student
  end

  it "sends someone enrolled without a group to the check first" do
    get lecture_home_path(lecture)

    expect(response).to redirect_to(participation_check_path)
    follow_redirect!
    expect(response.body).to include(CGI.escapeHTML(lecture.title_term_info_no_type))
  end

  it "lets them go on once they said they take part" do
    get lecture_home_path(lecture)
    patch confirm_participation_path(lecture)

    expect(response).to redirect_to(participation_check_path)
    follow_redirect!
    expect(response).to redirect_to(lecture_home_path(lecture))
    follow_redirect!
    expect(CGI.unescapeHTML(response.body))
      .to include(I18n.t("registration.user_registration.participation.no_group"))
  end

  it "labels each lecture's confirmation field on its own" do
    other = create(:lecture, :released_for_all, term: term)
    create(:tutorial, lecture: other, skip_campaigns: true)
    other.add_user_to_roster!(student)

    get participation_check_path

    [lecture, other].each do |each_lecture|
      field = "#{LeaveLectureComponent.dialog_id(each_lecture)}-confirmation"
      expect(response.body).to include(%(for="#{field}")).and(include(%(id="#{field}")))
    end
  end

  it "comes back to the check after leaving a lecture from it" do
    delete lecture_membership_path(lecture),
           params: { confirmation: lecture.course.short_title, from_check: 1 }

    expect(response).to redirect_to(participation_check_path)
    expect(lecture.members).not_to include(student)
  end
end
