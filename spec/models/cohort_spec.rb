require "rails_helper"

RSpec.describe(Cohort, type: :model) do
  it "has a valid factory" do
    expect(build(:cohort)).to be_valid
  end

  describe "validations" do
    it "is invalid without a title" do
      cohort = build(:cohort, title: nil)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:title]).to be_present
    end

    it "is invalid with a negative capacity" do
      cohort = build(:cohort, capacity: -1)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:capacity]).to be_present
    end

    it "is valid with a nil capacity" do
      cohort = build(:cohort, capacity: nil)
      expect(cohort).to be_valid
    end
  end

  describe "associations" do
    it "belongs to a context" do
      association = described_class.reflect_on_association(:context)
      expect(association.macro).to eq(:belongs_to)
    end
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
