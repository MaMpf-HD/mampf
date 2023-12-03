require "rails_helper"

RSpec.describe(Watchlist, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:watchlist, :with_user)).to be_valid
  end

  it "must have a name" do
    watchlist = Watchlist.new(name: nil)
    watchlist.valid?
    expect(watchlist.errors[:name]).to include("muss ausgefüllt werden")
  end

  it "must have a unique name" do
    first_watchlist = FactoryBot.create(:watchlist, :with_user)
    second_watchlist = Watchlist.new(user_id: first_watchlist.user_id, name: first_watchlist.name)
    expect(second_watchlist).to be_invalid
  end

  it "can be public" do
    watchlist = FactoryBot.build(:watchlist, :with_user)
    watchlist.public = true
    expect(watchlist.public).to eq(true)
  end

  it "ownership can be tested" do
    watchlist = FactoryBot.build(:watchlist, :with_user)
    user = FactoryBot.build(:user)

    expect(watchlist.owned_by?(user)).to eq(false)
    expect(watchlist.owned_by?(watchlist.user)).to eq(true)
  end
end
