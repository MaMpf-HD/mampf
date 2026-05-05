require "rails_helper"

RSpec.describe(Exam, type: :model) do
  it "has a valid factory" do
    expect(build(:exam)).to be_valid
  end

  describe "validations" do
    it "is invalid without a title" do
      expect(build(:exam, title: nil)).to be_invalid
    end

    it "is invalid without a lecture" do
      expect(build(:exam, lecture: nil)).to be_invalid
    end

    it "is valid without a date" do
      expect(build(:exam, :oral)).to be_valid
    end

    it "is invalid with negative capacity" do
      expect(build(:exam, capacity: -1)).to be_invalid
    end

    it "is invalid with zero capacity" do
      expect(build(:exam, capacity: 0)).to be_invalid
    end

    it "is valid with positive capacity" do
      expect(build(:exam, capacity: 100)).to be_valid
    end

    it "is valid with nil capacity" do
      expect(build(:exam, capacity: nil)).to be_valid
    end
  end

  describe "helpers" do
    it "formats the registration title with the exam date" do
      exam = build(:exam, :with_date, title: "Oral Exam")

      expect(exam.registration_title).to include("Oral Exam")
    end

    it "is destructible by default" do
      expect(build(:exam)).to be_destructible
    end
  end
end