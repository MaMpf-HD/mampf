require "rails_helper"

RSpec.describe(WatchlistEntry, type: :model) do
  it "has a valid factory" do
    expect(FactoryBot.build(:watchlist_entry, :with_watchlist, :with_medium)).to be_valid
  end

  it "must have a medium" do
    entry = FactoryBot.build(:watchlist_entry, :with_watchlist)
    expect(entry).not_to be_valid
    expect(entry.errors).to have_key(:medium)
    expect(entry.errors).not_to have_key(:watchlist)
  end

  it "must have a watchlist" do
    entry = FactoryBot.build(:watchlist_entry, :with_medium)
    expect(entry).not_to be_valid
    expect(entry.errors).to have_key(:watchlist)
    expect(entry.errors).not_to have_key(:medium)
  end

  it "can only be once inside a watchlist" do
    entry = FactoryBot.create(:watchlist_entry, :with_watchlist, :with_medium)
    second_entry = WatchlistEntry.new(watchlist: entry.watchlist, medium: entry.medium)
    expect(second_entry).to be_invalid
  end
end
