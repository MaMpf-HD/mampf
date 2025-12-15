require "rails_helper"

RSpec.describe(TutorialMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:tutorial_membership)).to be_valid
  end
end
