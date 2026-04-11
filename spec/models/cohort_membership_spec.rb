require "rails_helper"

RSpec.describe(CohortMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort_membership)).to be_valid
  end

  describe "validations" do
    let(:cohort) { create(:cohort) }
    let(:user) { create(:user) }

    it "is invalid for duplicate user within the same cohort" do
      create(:cohort_membership, cohort: cohort, user: user)

      duplicate = build(:cohort_membership, cohort: cohort, user: user)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors.of_kind?(:user_id, :taken)).to be(true)
    end

    it "allows the same user in different cohorts" do
      other_cohort = create(:cohort)
      create(:cohort_membership, cohort: cohort, user: user)

      membership = build(:cohort_membership, cohort: other_cohort, user: user)

      expect(membership).to be_valid
    end

    it "raises RecordInvalid for duplicate create! with model errors" do
      create(:cohort_membership, cohort: cohort, user: user)

      expect do
        create(:cohort_membership, cohort: cohort, user: user)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
