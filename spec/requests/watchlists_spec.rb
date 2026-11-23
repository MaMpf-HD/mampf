require "rails_helper"

RSpec.describe("Watchlists", type: :request) do
  let(:user) { create(:confirmed_user) }

  before { sign_in user }

  describe "GET /watchlists/:id" do
    it "shows the description as the text that was typed, line by line" do
      typed = "Videos for the exam\n" \
              'and a <b class="big" name="title">bold</b> word, <img src="x.png">'
      watchlist = create(:watchlist, user: user, description: typed)

      get watchlist_path(watchlist)

      description = Nokogiri::HTML(response.body)
                            .at_css("#collapseDescription p")
      expect(description.text).to eq(typed)
      expect(description.elements.map(&:name)).to eq(["br"])
    end
  end
end
