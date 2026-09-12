require "rails_helper"

RSpec.describe("Dashboard::Bookmarks", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }

  before do
    sign_in user
  end

  describe "POST /dashboard/bookmarks/:lecture_id" do
    it "bookmarks a published lecture and re-renders the dashboard bands" do
      post dashboard_bookmark_path(lecture), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboardLectureCards")
      expect(lecture.in?(user.reload.lectures)).to be(true)
    end

    it "is idempotent" do
      user.subscribe_lecture!(lecture)

      post dashboard_bookmark_path(lecture), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(user.reload.lectures.where(id: lecture.id).count).to eq(1)
    end

    it "scopes the re-rendered bands to the given term" do
      other_term = create(:term)
      other_lecture = create(:lecture, :released_for_all, term: other_term)
      user.subscribe_lecture!(other_lecture)

      post dashboard_bookmark_path(lecture),
           params: { term: other_term.id }, as: :turbo_stream

      expect(response.body).to include(other_lecture.title_no_term)
    end

    it "refuses a lecture behind a passphrase" do
      lecture.update!(passphrase: "secret")

      post dashboard_bookmark_path(lecture), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect(lecture.in?(user.reload.lectures)).to be(false)
    end

    it "refuses an unpublished lecture" do
      draft = create(:lecture)

      post dashboard_bookmark_path(draft), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
      expect(draft.in?(user.reload.lectures)).to be(false)
    end

    it "404s for an unknown lecture" do
      post dashboard_bookmark_path(0), as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /dashboard/bookmarks/:lecture_id" do
    it "removes a bookmark and re-renders the dashboard bands" do
      user.subscribe_lecture!(lecture)

      delete dashboard_bookmark_path(lecture), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboardLectureCards")
      expect(lecture.in?(user.reload.lectures)).to be(false)
    end

    it "also drops the lecture from favorites" do
      user.subscribe_lecture!(lecture)
      user.favorite_lectures << lecture

      delete dashboard_bookmark_path(lecture), as: :turbo_stream

      expect(user.reload.favorite_lectures).not_to include(lecture)
    end
  end
end
