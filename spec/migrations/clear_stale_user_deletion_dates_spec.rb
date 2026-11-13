require "rails_helper"
require Rails.root.join("db/migrate/20261113000003_clear_stale_user_deletion_dates")

RSpec.describe(ClearStaleUserDeletionDates) do
  def migrate
    ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) }
  end

  # The cleaner deletes whoever is due on its next run; such an account must
  # get through that run and be warned again instead.
  it "spares an account whose deletion date passed during the pause" do
    user = create(:confirmed_user, deletion_date: 11.months.ago.to_date,
                                   current_sign_in_at: 2.years.ago)

    migrate
    UserCleaner.new.handle_inactive_users!

    expect(User.find_by(id: user.id)&.deletion_date).to eq(Date.current + 40.days)
  end

  it "clears a deletion date that was still ahead as well" do
    user = create(:confirmed_user, deletion_date: 3.days.from_now.to_date)

    migrate

    expect(user.reload.deletion_date).to be_nil
  end
end
