require "rails_helper"

RSpec.describe("Media", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) do
    create(:confirmed_user, admin: true)
  end
  let!(:medium_ruby) { create(:valid_medium, description: "An introduction to Ruby") }
  let!(:medium_python) { create(:valid_medium, description: "A guide to Python") }

  before do
    sign_in user
  end

  describe "GET /media" do
    let(:lecture) { create(:lecture, :released_for_all) }
    let!(:medium_in_lecture) do
      create(:lecture_medium, teachable: lecture, sort: "LessonMaterial",
                              description: "Content for this lecture")
    end
    let!(:medium_elsewhere) do
      create(:lecture_medium, sort: "LessonMaterial", description: "Content from another source")
    end

    it "returns a successful response" do
      # The media#index action requires a :project parameter to scope the search.
      get media_path(id: lecture.id, project: "lesson_material")
      expect(response).to have_http_status(:ok)
    end

    it "returns only the media associated with the specified lecture" do
      get media_path(id: lecture.id, project: "lesson_material")
      expect(response.body).to include(medium_in_lecture.description)
      expect(response.body).not_to include(medium_elsewhere.description)
    end
  end

  describe "GET /media/search" do
    it "returns a successful response" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response).to have_http_status(:ok)
    end

    it "returns the correct media in the response body" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response.body).to include(medium_ruby.description)
      expect(response.body).not_to include(medium_python.description)
    end
  end
end
