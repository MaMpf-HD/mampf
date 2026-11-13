require "rails_helper"

RSpec.describe(StudentPerformance::Record, type: :model) do
  describe "factory" do
    it "creates a valid record" do
      record = FactoryBot.create(:student_performance_record)
      expect(record).to be_valid
      expect(record.points_total_materialized).to eq(0)
      expect(record.achievements_met_ids).to eq([])
    end
  end

  # The lists may still hold a test that has lost its threshold or been
  # deleted, so the count is taken among the tests the caller names.
  describe "the tests passed and failed" do
    let(:record) do
      FactoryBot.build(:student_performance_record, tests_passed_ids: [11, 12, 99],
                                                    tests_failed_ids: [13])
    end

    it "counts them among the tests it is given" do
      expect(record.tests_passed_among([11, 12, 13])).to eq(2)
      expect(record.tests_failed_among([11, 12, 13])).to eq(1)
      expect(record.tests_passed_among([])).to eq(0)
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      record = FactoryBot.build(:student_performance_record, lecture: nil)
      expect(record).not_to be_valid
    end

    it "belongs to a user" do
      record = FactoryBot.build(:student_performance_record, user: nil)
      expect(record).not_to be_valid
    end
  end

  describe "validations" do
    it "enforces uniqueness of lecture/user pair" do
      record = FactoryBot.create(:student_performance_record)
      duplicate = FactoryBot.build(:student_performance_record,
                                   lecture: record.lecture,
                                   user: record.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:lecture_id]).to be_present
    end

    it "allows same user in different lectures" do
      record = FactoryBot.create(:student_performance_record)
      other = FactoryBot.build(:student_performance_record,
                               user: record.user)
      expect(other).to be_valid
    end

    it "allows same lecture for different users" do
      record = FactoryBot.create(:student_performance_record)
      other = FactoryBot.build(:student_performance_record,
                               lecture: record.lecture)
      expect(other).to be_valid
    end
  end
end
