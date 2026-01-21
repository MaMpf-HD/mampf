require "rails_helper"

RSpec.describe(ActivityStreakResetter, type: :model) do
  it "has a factory" do
    expect(FactoryBot.build(:activity_streak_resetter))
      .to be_kind_of(ActivityStreakResetter)
  end

  describe "with sample submissions" do
    describe "#reset" do
      it "resets broken streaks" do
        resetter = FactoryBot.build(:activity_streak_resetter)
        user = FactoryBot.create(:confirmed_user)
        lecture = FactoryBot.create(:lecture)
        streak = FactoryBot.create(
          :streak,
          user: user,
          streakable: lecture,
          value: 2,
          last_activity: Time.current.prev_week.prev_week
        )
        resetter.reset

        expect(streak.reload.value).to eq(0)
      end

      it "does not reset intact streaks" do
        resetter = FactoryBot.build(:activity_streak_resetter)
        user = FactoryBot.create(:confirmed_user)
        lecture = FactoryBot.create(:lecture)
        streak = FactoryBot.create(
          :streak,
          user: user,
          streakable: lecture,
          value: 2,
          last_activity: Time.current
        )
        resetter.reset

        expect(streak.reload.value).to eq(2)
      end
    end
  end
end
