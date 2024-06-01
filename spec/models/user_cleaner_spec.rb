require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  it "assigns a deletion date to inactive users" do
    inactive_user = FactoryBot.create(:user, last_sign_in_at: 7.months.ago)
    active_user = FactoryBot.create(:user, last_sign_in_at: 5.months.ago)

    UserCleaner.new.set_deletion_date_for_inactive_users
    inactive_user.reload
    active_user.reload

    expect(inactive_user.deletion_date).to eq(Date.current + 40.days)
    expect(active_user.deletion_date).to be_nil
  end

  it "unassigns a deletion date from recently active users" do
    deletion_date = Date.current + 5.days
    user_inactive = FactoryBot.create(:user, deletion_date: deletion_date,
                                             last_sign_in_at: 7.months.ago)
    user_inactive2 = FactoryBot.create(:user, deletion_date: deletion_date,
                                              last_sign_in_at: 6.months.ago - 1.day)
    user_active = FactoryBot.create(:user, deletion_date: deletion_date,
                                           last_sign_in_at: 6.months.ago)
    user_active_recently = FactoryBot.create(:user, deletion_date: deletion_date,
                                                    last_sign_in_at: 2.days.ago)

    UserCleaner.new.unset_deletion_date_for_recently_active_users
    user_inactive.reload
    user_inactive2.reload
    user_active.reload
    user_active_recently.reload

    expect(user_inactive.deletion_date).to eq(deletion_date)
    expect(user_inactive2.deletion_date).to eq(deletion_date)
    expect(user_active.deletion_date).to be_nil
    expect(user_active_recently.deletion_date).to be_nil
  end

  it "deletes users with a deletion date in the past or present" do
    user_past1 = FactoryBot.create(:user, deletion_date: Date.current - 1.day)
    user_past2 = FactoryBot.create(:user, deletion_date: Date.current - 1.year)
    user_present = FactoryBot.create(:user, deletion_date: Date.current)

    UserCleaner.new.delete_users_according_to_deletion_date

    expect(User.where(id: user_past1.id)).not_to exist
    expect(User.where(id: user_past2.id)).not_to exist
    expect(User.where(id: user_present.id)).not_to exist
  end

  it "does not delete users with a deletion date in the future" do
    user_future1 = FactoryBot.create(:user, deletion_date: Date.current + 1.day)
    user_future2 = FactoryBot.create(:user, deletion_date: Date.current + 1.year)

    UserCleaner.new.delete_users_according_to_deletion_date

    expect(User.where(id: user_future1.id)).to exist
    expect(User.where(id: user_future2.id)).to exist
  end

  it "does not delete users without a deletion date" do
    user = FactoryBot.create(:user, deletion_date: nil)
    UserCleaner.new.delete_users_according_to_deletion_date
    expect(User.where(id: user.id)).to exist
  end

  it "deletes only generic users" do
    deletion_date = Date.current - 1.day
    user_generic = FactoryBot.create(:user, deletion_date: deletion_date)

    # Non-generic users are either admins, teachers or editors
    user_admin = FactoryBot.create(:user, deletion_date: deletion_date, admin: true)
    user_teacher = FactoryBot.create(:user, deletion_date: deletion_date)
    FactoryBot.create(:lecture, teacher: user_teacher)
    user_editor = FactoryBot.create(:user, deletion_date: deletion_date)
    FactoryBot.create(:lecture, editors: [user_editor])

    UserCleaner.new.delete_users_according_to_deletion_date

    expect(User.where(id: user_generic.id)).not_to exist
    expect(User.where(id: user_admin.id)).to exist
    expect(User.where(id: user_teacher.id)).to exist
    expect(User.where(id: user_editor.id)).to exist
  end

  # TODO: https://stackoverflow.com/questions/27647749/how-to-test-actionmailer-deliver-later-with-rspec
end
