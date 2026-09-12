require "rails_helper"

RSpec.describe("Dashboard::Terms", type: :request) do
  let(:user) { create(:confirmed_user) }

  before do
    sign_in user
  end

  describe "GET /dashboard/term" do
    it "swaps the term-dependent regions in place for the given term" do
      other_term = create(:term, :winter, year: 2025)
      here = create(:lecture, :released_for_all,
                    course: create(:course, title: "Here Now"))
      there = create(:lecture, :released_for_all,
                     course: create(:course, title: "Over There"),
                     term: other_term)
      here.lecture_memberships.create!(user: user)
      there.lecture_memberships.create!(user: user)

      get dashboard_term_path(term: other_term.dashboard_param),
          as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="dashboardLectureCards"')
      expect(response.body)
        .to include('target="lecture-search-term-select-wrapper"')
      expect(response.body).to include('target="lecture-search-term-field"')
      expect(response.body).to include("Over There")
      expect(response.body).not_to include("Here Now")
    end
  end
end
