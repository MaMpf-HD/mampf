require "rails_helper"

RSpec.describe(Cohort, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort)).to be_valid
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_numericality_of(:capacity).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe "associations" do
    it { should belong_to(:context) }
  end

  describe "Registerable interface" do
    it "includes Registration::Registerable" do
      expect(Cohort.ancestors).to include(Registration::Registerable)
    end

    it "raises NotImplementedError for allocated_user_ids" do
      cohort = build(:cohort)
      expect { cohort.allocated_user_ids }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for materialize_allocation!" do
      cohort = build(:cohort)
      expect do
        cohort.materialize_allocation!(user_ids: [], campaign: nil)
      end.to raise_error(NotImplementedError)
    end
  end
end
