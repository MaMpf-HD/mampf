require "rails_helper"

RSpec.describe("Watchlists", type: :request) do
  let(:user) { create(:confirmed_user) }

  before { sign_in user }

  describe "GET /watchlists/:id" do
    # A quiz medium carries no teachable, and a watchlist takes any medium.
    it "shows a watchlist that holds a medium without a teachable" do
      watchlist = Watchlist.create!(user: user, name: "Wiederholung")
      medium = create(:medium, :with_description, teachable: nil, sort: "RandomQuiz")
      WatchlistEntry.create!(watchlist: watchlist, medium: medium,
                             medium_position: 1)

      get watchlist_path(watchlist)

      expect(response).to have_http_status(:ok)
    end
  end
end
