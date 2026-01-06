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
    it_behaves_like "a registerable model"
  end

  describe "Rosterable interface" do
    it_behaves_like "a rosterable model"
  end

  describe "Registerable interface" do
    it "includes Registration::Registerable" do
      expect(Cohort.ancestors).to include(Registration::Registerable)
    end

    it "includes Rosters::Rosterable" do
      expect(Cohort.ancestors).to include(Rosters::Rosterable)
    end

    it "implements roster_entries" do
      cohort = build(:cohort)
      expect(cohort).to respond_to(:roster_entries)
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

  describe "#materialize_allocation!" do
    let(:lecture) { create(:lecture) }
    let(:cohort) { create(:cohort, context: lecture) }
    let(:campaign) { create(:registration_campaign) }
    let(:user) { create(:confirmed_user) }

    it "does NOT propagate users to the lecture roster (Sidecar behavior)" do
      expect(lecture.lecture_memberships.where(user: user)).to be_empty

      cohort.materialize_allocation!(user_ids: [user.id], campaign: campaign)

      expect(lecture.lecture_memberships.where(user: user)).not_to exist
    end
  end
end
