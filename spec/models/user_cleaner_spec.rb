require "rails_helper"

RSpec.describe(UserCleaner, type: :model) do
  describe "Inactive users" do
    it "get assigned a deletion date" do
      inactive_user = FactoryBot.create(:user, last_sign_in_at: 7.months.ago)
      active_user = FactoryBot.create(:user, last_sign_in_at: 5.months.ago)

      UserCleaner.new.set_deletion_date_for_inactive_users

      inactive_user.reload
      active_user.reload

      expect(inactive_user.deletion_date).to eq(Date.current + 40.days)
      expect(active_user.deletion_date).to be_nil
    end
  end
end
