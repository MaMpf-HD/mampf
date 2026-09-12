require "rails_helper"

RSpec.describe("Dashboard::RegistrationNotices", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:campaign) do
    create(:registration_campaign, :open, campaignable: lecture)
  end
  let!(:registration) do
    create(:registration_user_registration, :rejected,
           user: user,
           registration_campaign: campaign,
           registration_item: campaign.registration_items.first)
  end

  before do
    sign_in user
  end

  describe "DELETE /dashboard/registration_notice/:lecture_id" do
    it "dismisses the rejected registration and re-renders the dashboard bands" do
      delete dashboard_registration_notice_path(lecture), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboardLectureCards")
      expect(registration.reload.dismissed_at).not_to be_nil
    end

    it "does not bookmark the lecture by default" do
      delete dashboard_registration_notice_path(lecture), as: :turbo_stream

      expect(lecture.in?(user.reload.lectures)).to be(false)
    end

    it "drops the lecture from the dashboard entirely once dismissed" do
      delete dashboard_registration_notice_path(lecture), as: :turbo_stream

      expect(user.reload.current_enrolled_lectures(lecture.term))
        .not_to include(lecture)
      expect(user.current_bookmarked_lectures(lecture.term))
        .not_to include(lecture)
    end

    it "keeps the lecture bookmarked when asked to" do
      delete dashboard_registration_notice_path(lecture),
             params: { keep_bookmarked: true }, as: :turbo_stream

      expect(lecture.in?(user.reload.lectures)).to be(true)
      expect(user.current_bookmarked_lectures(lecture.term)).to include(lecture)
    end

    it "404s for an unknown lecture" do
      delete dashboard_registration_notice_path(0), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end

    it "is idempotent when the notice was already dismissed" do
      registration.dismiss!

      expect do
        delete(dashboard_registration_notice_path(lecture), as: :turbo_stream)
      end.not_to raise_error

      expect(response).to have_http_status(:ok)
    end

    it "leaves another user's rejected registration for the same lecture untouched" do
      other_user = create(:confirmed_user)
      other_registration = create(
        :registration_user_registration, :rejected,
        user: other_user,
        registration_campaign: campaign,
        registration_item: campaign.registration_items.first
      )

      delete dashboard_registration_notice_path(lecture), as: :turbo_stream

      expect(other_registration.reload.dismissed_at).to be_nil
    end
  end
end
