require 'rails_helper'

RSpec.describe UserCleaner, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:user_cleaner))
      .to be_kind_of(UserCleaner)
  end

  it 'can destroy users' do
    expect(User.all.size).to eq 0
    u = FactoryBot.build(:user_cleaner, :with_mail)
    expect(User.all.size).to eq 1
    u.destroy_users
    expect(User.all.size).to eq 0
  end
end
