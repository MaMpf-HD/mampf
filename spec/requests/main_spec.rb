require "rails_helper"

RSpec.describe("Main", type: :request) do
  let(:user) { create(:confirmed_user) }
  let!(:term) { create(:term, :summer, :active, year: 2025) }

  before do
    sign_in user
  end

  describe "GET / (start page)" do
    def lecture_with_title(title)
      create(:lecture, course: create(:course, title: title), term: term)
    end

    it "renders successfully" do
      get root_path

      expect(response).to be_successful
    end

    it "shows the lectures the user holds a place in, then the bookmarked ones" do
      enrolled = lecture_with_title("Roster Topology")
      bookmarked = lecture_with_title("Bookmarked Geometry")
      enrolled.lecture_memberships.create!(user: user)
      user.subscribe_lecture!(bookmarked)

      get root_path

      expect(response.body).to include("dashboard-enrolled-lectures")
      expect(response.body).to include("dashboard-bookmarked-lectures")
      expect(response.body.index("Roster Topology"))
        .to be < response.body.index("Bookmarked Geometry")
    end

    it "does not list an enrolled lecture a second time as bookmarked" do
      lecture = lecture_with_title("Roster Topology")
      lecture.lecture_memberships.create!(user: user)
      user.subscribe_lecture!(lecture)

      get root_path

      expect(response.body).to include("dashboard-enrolled-lectures")
      expect(response.body).not_to include("dashboard-bookmarked-lectures")
    end

    it "leaves out a section that has nothing in it" do
      lecture = lecture_with_title("Roster Topology")
      lecture.lecture_memberships.create!(user: user)

      get root_path

      expect(response.body).to include("dashboard-enrolled-lectures")
      expect(response.body).not_to include("dashboard-bookmarked-lectures")
    end

    it "shows the user's talks alongside the lectures they are registered for" do
      seminar = create(:lecture, :released_for_all, sort: "seminar", term: term)
      talk = create(:talk, lecture: seminar, title: "Divisibility")
      talk.speakers << user

      get root_path

      expect(response.body).to include("dashboard-enrolled-lectures")
      expect(response.body).not_to include("dashboard-bookmarked-lectures")
      expect(response.body).to include("Divisibility")
    end

    it "shows the empty state when there is nothing at all" do
      get root_path

      expect(response.body).to include("dashboard-empty-state")
    end

    describe "the semester picker" do
      it "is absent while only one semester exists" do
        get root_path

        expect(response.body).not_to include("dashboard-term-select")
      end

      it "appears once there is more than one semester to pick from" do
        create(:term, :winter, year: 2025)

        get root_path

        expect(response.body).to include("dashboard-term-select")
      end
    end

    describe "?term=<id>" do
      let!(:other_term) { create(:term, :winter, year: 2025) }

      it "scopes the dashboard sections to the given semester" do
        here = lecture_with_title("Here Now")
        there = create(:lecture, course: create(:course, title: "Over There"),
                                 term: other_term)
        here.lecture_memberships.create!(user: user)
        there.lecture_memberships.create!(user: user)

        get root_path(term: other_term.id)

        expect(response.body).to include("Over There")
        expect(response.body).not_to include("Here Now")
      end

      it "falls back to the active term for an unknown id" do
        here = lecture_with_title("Here Now")
        here.lecture_memberships.create!(user: user)

        get root_path(term: 0)

        expect(response.body).to include("Here Now")
      end
    end
  end
end
