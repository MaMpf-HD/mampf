require "rails_helper"

RSpec.describe(Streak, type: :model) do
  it "is invalid if the value is negative" do
    streak = FactoryBot.build(:streak)
    streak.value = -3
    expect(streak).not_to be_valid
  end

  it "is invalid if the last_activity more than 5 minutes in the future" do
    streak = FactoryBot.build(:streak)
    streak.last_activity = 1.week.from_now
    expect(streak).not_to be_valid
  end
end
