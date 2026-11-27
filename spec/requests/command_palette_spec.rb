require "rails_helper"

RSpec.describe("CommandPalette", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "GET /command_palette/catalog" do
    it "lists published lectures only" do
      published = create(:lecture, :released_for_all)
      unpublished = create(:lecture)

      get command_palette_catalog_path

      expect(response.parsed_body.pluck("id")).to include(published.id)
      expect(response.parsed_body.pluck("id")).not_to include(unpublished.id)
    end

    it "answers a request for unchanged data with 304" do
      create(:lecture, :released_for_all)
      get command_palette_catalog_path
      etag = response.headers["ETag"]

      get command_palette_catalog_path, headers: { "If-None-Match" => etag }

      expect(response).to have_http_status(:not_modified)
    end

    it "refuses a visitor who is not signed in" do
      sign_out user

      get command_palette_catalog_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /command_palette/me" do
    def my_lecture(lecture)
      get(command_palette_me_path)
      response.parsed_body["lectures"].find { |entry| entry["id"] == lecture.id }
    end

    it "offers a student the submissions, but not the edit page" do
      lecture = create(:lecture, :released_for_all)
      create(:lecture_bookmark, lecture: lecture, user: user)

      destinations = my_lecture(lecture)["destinations"]

      expect(destinations).to include("submissions", "exercises")
      expect(destinations).not_to include("assessments")
    end

    it "offers the teacher the edit page, but not the submissions" do
      lecture = create(:lecture, teacher: user)

      destinations = my_lecture(lecture)["destinations"]

      expect(destinations["assessments"])
        .to eq(edit_lecture_path(lecture, tab: "assessments"))
      expect(destinations).not_to include("submissions")
    end

    it "offers no groups and participants tabs of a legacy seminar" do
      lecture = create(:seminar, teacher: user, legacy_seminar: true)

      destinations = my_lecture(lecture)["destinations"]

      expect(destinations).to include("people")
      expect(destinations).not_to include("groups", "participants")
    end

    it "offers the forum only of a lecture that has one" do
      with_forum = create(:lecture, :released_for_all, :with_forum)
      without_forum = create(:lecture, :released_for_all)
      [with_forum, without_forum].each do |lecture|
        create(:lecture_bookmark, lecture: lecture, user: user)
      end

      expect(my_lecture(with_forum)["destinations"]["forum"])
        .to eq("/forum/#{with_forum.forum_id}")
      expect(my_lecture(without_forum)["destinations"]).not_to include("forum")
    end

    it "offers no pages of a lecture whose content is locked" do
      lecture = create(:lecture, :released_for_all, passphrase: "secret")
      user.favorite_lectures << lecture

      expect(my_lecture(lecture)["destinations"]).to be_empty
    end

    it "does not offer the lecture's home page, as the lecture itself leads there" do
      lecture = create(:lecture, :released_for_all)
      create(:lecture_bookmark, lecture: lecture, user: user)

      expect(my_lecture(lecture)["destinations"].values)
        .not_to include(lecture_home_path(lecture))
    end

    it "leaves out unpublished lectures the user only tutors" do
      lecture = create(:lecture)
      create(:tutorial, lecture: lecture, tutors: [user])

      get(command_palette_me_path)

      expect(response.parsed_body["lectures"].pluck("id")).not_to include(lecture.id)
    end

    it "tells lectures the user holds a place in from bookmarked ones" do
      enrolled = create(:lecture, :released_for_all)
      create(:lecture_membership, lecture: enrolled, user: user)
      bookmarked = create(:lecture, :released_for_all)
      create(:lecture_bookmark, lecture: bookmarked, user: user)
      taught = create(:lecture, teacher: user)

      expect([enrolled, bookmarked, taught].map { |lecture| my_lecture(lecture)["participation"] })
        .to eq(["enrolled", "bookmarked", "staff"])
    end

    it "counts the terms between a lecture's term and the active one" do
      create(:term, :summer, :active, year: 2026)
      before = create(:lecture, :released_for_all,
                      term: create(:term, :winter, year: 2025))
      after = create(:lecture, :released_for_all,
                     term: create(:term, :winter, year: 2026))
      older = create(:lecture, :released_for_all,
                     term: create(:term, :summer, year: 2024))
      [before, after, older].each do |lecture|
        create(:lecture_bookmark, lecture: lecture, user: user)
      end

      expect([before, after, older].map { |lecture| my_lecture(lecture)["term_distance"] })
        .to eq([1, 1, 2])
    end

    it "lists favorites first, by course and with the newest term first" do
      course = create(:course)
      summer = create(:term, :summer, year: 2025)
      winter = create(:term, :winter, year: 2025)
      older = create(:term, :winter, year: 2024)
      favorites = [summer, older, winter].map do |term|
        create(:lecture, :released_for_all, course: course, term: term)
      end
      other = create(:lecture, :released_for_all)
      user.favorite_lectures << favorites
      create(:lecture_bookmark, lecture: other, user: user)

      get command_palette_me_path

      expect(response.parsed_body["lectures"].pluck("id"))
        .to eq([favorites[2], favorites[0], favorites[1], other].map(&:id))
    end

    it "labels the pages in the user's locale and finds them in all locales" do
      user.update(locale: "en")

      get command_palette_me_path

      exercises = response.parsed_body["destinations"].find { |d| d["key"] == "exercises" }
      expect(exercises["label"]).to eq("Exercises")
      expect(exercises["keywords"]).to include("Übungen")
    end
  end
end
