require "rails_helper"

RSpec.describe(Assessment::Participation, type: :model) do
  describe "factory" do
    it "creates a valid default participation" do
      participation = FactoryBot.create(:assessment_participation)
      expect(participation).to be_valid
    end

    it "creates a participation with tutorial" do
      participation = FactoryBot.create(:assessment_participation, :with_tutorial)
      expect(participation.tutorial).to be_present
    end

    it "creates a submitted participation" do
      participation = FactoryBot.create(:assessment_participation, :submitted)
      expect(participation.status).to eq("submitted")
      expect(participation.submitted_at).to be_present
    end

    it "creates a graded participation" do
      participation = FactoryBot.create(:assessment_participation, :graded)
      expect(participation.status).to eq("graded")
      expect(participation.graded_at).to be_present
    end

    it "creates a participation with numeric grade" do
      participation = FactoryBot.create(:assessment_participation, :with_numeric_grade)
      expect([1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0,
              5.0]).to include(participation.grade_numeric)
    end
  end

  describe "validations" do
    let(:assessment) { FactoryBot.create(:assessment) }

    it "requires user to be unique per assessment" do
      user = FactoryBot.create(:confirmed_user)
      FactoryBot.create(:assessment_participation, assessment: assessment, user: user)

      duplicate = FactoryBot.build(:assessment_participation, assessment: assessment,
                                                              user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    context "grade_numeric validation" do
      it "accepts valid German grades" do
        valid_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]
        valid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           grade_numeric: grade)
          expect(participation).to be_valid
        end
      end

      it "rejects invalid grades" do
        invalid_grades = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.0]
        invalid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           grade_numeric: grade)
          expect(participation).not_to be_valid
          expect(participation.errors[:grade_numeric]).to be_present
        end
      end

      it "allows nil" do
        participation = FactoryBot.build(:assessment_participation, grade_numeric: nil)
        expect(participation).to be_valid
      end
    end
  end

  describe "enums" do
    it "supports all status values" do
      statuses = ["not_started", "in_progress", "submitted", "graded", "exempt"]
      statuses.each do |status|
        participation = FactoryBot.build(:assessment_participation, status: status)
        expect(participation.status).to eq(status)
      end
    end
  end
end
