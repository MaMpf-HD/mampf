require "rails_helper"

RSpec.describe(CohortMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort_membership)).to be_valid
  end
end
