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

  # A random quiz is what a self test leaves behind: it belongs to no lecture,
  # has no page of its own, and the cleanup throws it away a day later.
  it "refuses a random quiz" do
    quiz = FactoryBot.create(:medium, :with_description, teachable: nil,
                                                         sort: "RandomQuiz")
    entry = FactoryBot.build(:watchlist_entry, :with_watchlist, medium: quiz)

    expect(entry).not_to be_valid
    expect(entry.errors[:medium])
      .to include(I18n.t("activerecord.errors.models.watchlist_entry" \
                         ".attributes.medium.improper"))
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
