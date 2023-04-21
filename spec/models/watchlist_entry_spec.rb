require 'rails_helper'

RSpec.describe WatchlistEntry, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:watchlist_entry, :with_watchlist, :with_medium)).to be_valid
  end

  it 'must have a medium' do
    entry = FactoryBot.build(:watchlist_entry, :with_watchlist)
    entry.valid?
    expect(entry.errors[:medium]).to include('muss ausgefüllt werden')
  end

  it 'must have a watchlist' do
    entry = FactoryBot.build(:watchlist_entry, :with_medium)
    entry.valid?
    expect(entry.errors[:watchlist]).to include('muss ausgefüllt werden')
  end

  it 'can only be once inside a watchlist' do
    entry = FactoryBot.create(:watchlist_entry, :with_watchlist, :with_medium)
    second_entry = WatchlistEntry.new(watchlist: entry.watchlist, medium: entry.medium)
    expect(second_entry).to be_invalid
  end
end
