require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  it "has a factory" do
    expect(FactoryBot.build(:user_cleaner))
      .to be_kind_of(UserCleaner)
  end
  # Right now, delete_ghosts is commented out in user_cleaner.rb
  # as we want to avoid accidental deletion of users in production.
  # We will come up with a new strategy for cleaning up old users.
  #
  # it "can destroy users" do
  #   n_users = User.all.size
  #   u = FactoryBot.build(:user_cleaner, :with_hashed_user)
  #   expect(User.all.size).to eq(n_users + 1)
  #   u.delete_ghosts
  #   expect(User.all.size).to eq(n_users)
  # end
end
