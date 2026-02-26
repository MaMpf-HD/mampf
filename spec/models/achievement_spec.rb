require "rails_helper"

RSpec.describe(Achievement, type: :model) do
  describe "factory" do
    it "creates a valid boolean achievement" do
      achievement = FactoryBot.create(:achievement)
      expect(achievement).to be_valid
      expect(achievement).to be_boolean
      expect(achievement.threshold).to be_nil
    end

    it "creates a valid numeric achievement" do
      achievement = FactoryBot.create(:achievement, :numeric)
      expect(achievement).to be_valid
      expect(achievement).to be_numeric
      expect(achievement.threshold).to eq(12)
    end

    it "creates a valid percentage achievement" do
      achievement = FactoryBot.create(:achievement, :percentage)
      expect(achievement).to be_valid
      expect(achievement).to be_percentage
      expect(achievement.threshold).to eq(75.0)
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      achievement = FactoryBot.build(:achievement, lecture: nil)
      expect(achievement).not_to be_valid
    end

    it "has many rule_achievements" do
      achievement = FactoryBot.create(:achievement)
      rule = FactoryBot.create(:student_performance_rule,
                               lecture: achievement.lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      expect(achievement.rule_achievements.count).to eq(1)
    end

    it "restricts deletion when rule_achievements exist" do
      achievement = FactoryBot.create(:achievement)
      rule = FactoryBot.create(:student_performance_rule,
                               lecture: achievement.lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      expect { achievement.destroy }.not_to change(Achievement, :count)
      expect(achievement.errors[:base]).to be_present
    end
  end

  describe "validations" do
    it "requires title" do
      achievement = FactoryBot.build(:achievement, title: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:title]).to be_present
    end

    it "requires value_type" do
      achievement = FactoryBot.build(:achievement, value_type: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:value_type]).to be_present
    end

    it "requires threshold for numeric type" do
      achievement = FactoryBot.build(:achievement, :numeric, threshold: nil)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:threshold]).to be_present
    end

    it "requires threshold for percentage type" do
      achievement = FactoryBot.build(:achievement, :percentage, threshold: nil)
      expect(achievement).not_to be_valid
    end

    it "rejects threshold for boolean type" do
      achievement = FactoryBot.build(:achievement, :boolean, threshold: 5)
      expect(achievement).not_to be_valid
      expect(achievement.errors[:threshold]).to be_present
    end

    it "rejects non-positive threshold" do
      achievement = FactoryBot.build(:achievement, :numeric, threshold: 0)
      expect(achievement).not_to be_valid
    end

    it "rejects percentage threshold above 100" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 101)
      expect(achievement).not_to be_valid
    end

    it "allows percentage threshold of 100" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 100)
      expect(achievement).to be_valid
    end

    it "allows percentage threshold of 0" do
      achievement = FactoryBot.build(:achievement, :percentage,
                                     threshold: 0)
      expect(achievement).to be_valid
    end
  end

  describe "enums" do
    it "defines value_type enum" do
      expect(described_class.value_types).to eq(
        "boolean" => 0, "numeric" => 1, "percentage" => 2
      )
    end
  end
end
