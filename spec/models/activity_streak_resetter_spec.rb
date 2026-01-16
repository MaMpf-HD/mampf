require "rails_helper"

RSpec.describe(ActivityStreakResetter, type: :model) do
  it "has a factory" do
    expect(FactoryBot.build(:activity_streak_resetter))
      .to be_kind_of(ActivityStreakResetter)
  end

  describe "with sample users" do
    describe "#reset" do
      it "resets broken activity_streaks" do
        user = FactoryBot.create(:confirmed_user,
                                 activity_streak: 4,
                                 last_activity: Time.zone.now.prev_week.prev_week)
        resetter = FactoryBot.build(:activity_streak_resetter)
        resetter.reset

        expect(user.reload.activity_streak).to eq(0)
      end

      it "does not reset active activity_streaks" do
        user = FactoryBot.create(:confirmed_user,
                                 activity_streak: 4,
                                 last_activity: Time.zone.now.prev_day)
        resetter = FactoryBot.build(:activity_streak_resetter)
        resetter.reset

        expect(user.reload.activity_streak).to eq(4)
      end
    end
  end
end
