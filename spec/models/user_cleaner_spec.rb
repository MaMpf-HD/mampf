require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  it "inactive users get assigned a deletion date" do
    inactive_user = FactoryBot.create(:user, last_sign_in_at: 7.months.ago)
    active_user = FactoryBot.create(:user, last_sign_in_at: 5.months.ago)

    UserCleaner.new.set_deletion_date_for_inactive_users
    inactive_user.reload
    active_user.reload

    expect(inactive_user.deletion_date).to eq(Date.current + 40.days)
    expect(active_user.deletion_date).to be_nil
  end

  it "deletes users with a deletion date in the past or present" do
    user_past1 = FactoryBot.create(:user, deletion_date: Date.current - 1.day)
    user_past2 = FactoryBot.create(:user, deletion_date: Date.current - 1.year)
    user_present = FactoryBot.create(:user, deletion_date: Date.current)
    user_future1 = FactoryBot.create(:user, deletion_date: Date.current + 1.day)
    user_future2 = FactoryBot.create(:user, deletion_date: Date.current + 1.year)

    UserCleaner.new.delete_users_according_to_deletion_date

    expect(User.where(id: user_past1.id)).not_to exist
    expect(User.where(id: user_past2.id)).not_to exist
    expect(User.where(id: user_present.id)).not_to exist
    expect(User.where(id: user_future1.id)).to exist
    expect(User.where(id: user_future2.id)).to exist
  end

  it "does not delete users without a deletion date" do
    user = FactoryBot.create(:user, deletion_date: nil)
    UserCleaner.new.delete_users_according_to_deletion_date
    expect(User.where(id: user.id)).to exist
  end

  it "deletes only generic users" do
    generic_user = FactoryBot.create(:user, deletion_date: Date.current - 1.day)
    admin_user = FactoryBot.create(:user, deletion_date: Date.current - 1.day, admin: true)

    UserCleaner.new.delete_users_according_to_deletion_date

    expect(User.where(id: generic_user.id)).not_to exist
    expect(User.where(id: admin_user.id)).to exist
  end
end
