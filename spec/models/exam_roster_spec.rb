require "rails_helper"

RSpec.describe(ExamRoster, type: :model) do
  it "has a valid factory" do
    expect(build(:exam_roster)).to be_valid
  end

  describe "validations" do
    it "is invalid without an exam" do
      expect(build(:exam_roster, exam: nil)).to be_invalid
    end

    it "is invalid without a user" do
      expect(build(:exam_roster, user: nil)).to be_invalid
    end

    it "is invalid with duplicate user for same exam" do
      roster = create(:exam_roster)
      duplicate = build(:exam_roster, exam: roster.exam, user: roster.user)
      expect(duplicate).to be_invalid
    end

    it "allows same user for different exams" do
      user = create(:confirmed_user)
      exam1 = create(:exam)
      exam2 = create(:exam)

      create(:exam_roster, exam: exam1, user: user)
      roster2 = build(:exam_roster, exam: exam2, user: user)

      expect(roster2).to be_valid
    end
  end

  describe "associations" do
    it "belongs to an exam" do
      roster = create(:exam_roster)
      expect(roster.exam).to be_a(Exam)
    end

    it "belongs to a user" do
      roster = create(:exam_roster)
      expect(roster.user).to be_a(User)
    end

    it "optionally belongs to a source_campaign" do
      roster = create(:exam_roster, :from_campaign)
      expect(roster.source_campaign).to be_a(Registration::Campaign)
    end

    it "allows nil source_campaign for manual additions" do
      roster = create(:exam_roster, source_campaign: nil)
      expect(roster).to be_valid
      expect(roster.source_campaign).to be_nil
    end
  end
end
