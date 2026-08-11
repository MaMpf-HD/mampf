require "rails_helper"

RSpec.describe(LectureMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:lecture_membership)).to be_valid
  end
end
