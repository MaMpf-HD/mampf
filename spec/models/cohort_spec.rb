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

    it "is invalid without a purpose" do
      cohort = build(:cohort, purpose: nil)
      expect(cohort).not_to be_valid
      expect(cohort.errors[:purpose]).to be_present
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

  describe "purpose enum" do
    it "supports general purpose" do
      cohort = create(:cohort, :general)
      expect(cohort.general?).to be(true)
    end

    it "supports enrollment purpose" do
      cohort = create(:cohort, :enrollment)
      expect(cohort.enrollment?).to be(true)
    end

    it "supports planning purpose" do
      cohort = create(:cohort, :planning)
      expect(cohort.planning?).to be(true)
    end
  end

  describe "propagate_to_lecture immutability" do
    it "cannot be changed after creation" do
      cohort = create(:cohort, propagate_to_lecture: false)

      expect { cohort.propagate_to_lecture = true }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  describe "database constraints" do
    it "prevents planning cohorts from propagating" do
      expect do
        create(:cohort, purpose: :planning, propagate_to_lecture: true)
      end.to raise_error(ActiveRecord::StatementInvalid, /planning_cohorts_must_not_propagate/)
    end

    it "enforces enrollment cohorts must propagate" do
      expect do
        create(:cohort, purpose: :enrollment, propagate_to_lecture: false)
      end.to raise_error(ActiveRecord::StatementInvalid, /enrollment_cohorts_must_propagate/)
    end

    it "allows general cohorts with either propagation setting" do
      expect(create(:cohort, purpose: :general, propagate_to_lecture: false)).to be_valid
      expect(create(:cohort, purpose: :general, propagate_to_lecture: true)).to be_valid
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

  describe "#lecture" do
    it "returns the context as lecture if it is a Lecture" do
      lecture = build(:lecture)
      cohort = build(:cohort, context: lecture)
      expect(cohort.lecture).to eq(lecture)
    end

    it "returns nil for lecture if context is not a Lecture" do
      cohort = build(:cohort, context: nil)
      expect(cohort.lecture).to be_nil
    end
  end
end
