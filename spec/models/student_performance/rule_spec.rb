require "rails_helper"

RSpec.describe(StudentPerformance::Rule, type: :model) do
  describe "factory" do
    it "creates a valid default rule" do
      rule = FactoryBot.create(:student_performance_rule)
      expect(rule).to be_valid
      expect(rule.active).to be(false)
    end

    it "creates a valid rule with percentage" do
      rule = FactoryBot.create(:student_performance_rule, :with_percentage)
      expect(rule).to be_valid
      expect(rule.min_percentage).to eq(50)
    end

    it "creates a valid rule with absolute points" do
      rule = FactoryBot.create(:student_performance_rule,
                               :with_absolute_points)
      expect(rule).to be_valid
      expect(rule.min_points_absolute).to eq(60)
    end

    it "creates a valid active rule" do
      rule = FactoryBot.create(:student_performance_rule, :active)
      expect(rule).to be_valid
      expect(rule.active).to be(true)
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      rule = FactoryBot.build(:student_performance_rule, lecture: nil)
      expect(rule).not_to be_valid
    end

    it "has many rule_achievements" do
      rule = FactoryBot.create(:student_performance_rule)
      achievement = FactoryBot.create(:achievement, lecture: rule.lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      expect(rule.rule_achievements.count).to eq(1)
    end

    it "has many required_achievements through rule_achievements" do
      rule = FactoryBot.create(:student_performance_rule)
      achievement = FactoryBot.create(:achievement, lecture: rule.lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      expect(rule.required_achievements).to include(achievement)
    end

    it "destroys rule_achievements when destroyed" do
      rule = FactoryBot.create(:student_performance_rule)
      achievement = FactoryBot.create(:achievement, lecture: rule.lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      expect { rule.destroy }
        .to change(StudentPerformance::RuleAchievement, :count).by(-1)
    end
  end

  describe "validations" do
    it "allows nil min_percentage" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: nil)
      expect(rule).to be_valid
    end

    it "rejects min_percentage below 0" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: -1)
      expect(rule).not_to be_valid
    end

    it "rejects min_percentage above 100" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: 101)
      expect(rule).not_to be_valid
    end

    it "allows min_percentage of 0" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: 0)
      expect(rule).to be_valid
    end

    it "allows min_percentage of 100" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: 100)
      expect(rule).to be_valid
    end

    it "allows nil min_points_absolute" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_points_absolute: nil)
      expect(rule).to be_valid
    end

    it "rejects negative min_points_absolute" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_points_absolute: -1)
      expect(rule).not_to be_valid
    end

    it "rejects both percentage and absolute thresholds" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: 50,
                              min_points_absolute: 60)
      expect(rule).not_to be_valid
      expect(rule.errors[:base]).to be_present
    end

    it "allows percentage without absolute" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: 50,
                              min_points_absolute: nil)
      expect(rule).to be_valid
    end

    it "allows absolute without percentage" do
      rule = FactoryBot.build(:student_performance_rule,
                              min_percentage: nil,
                              min_points_absolute: 60)
      expect(rule).to be_valid
    end
  end

  describe "unique active rule per lecture" do
    it "allows only one active rule per lecture" do
      lecture = FactoryBot.create(:lecture)
      FactoryBot.create(:student_performance_rule, :active,
                        lecture: lecture)
      expect do
        FactoryBot.create(:student_performance_rule, :active,
                          lecture: lecture)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows multiple inactive rules per lecture" do
      lecture = FactoryBot.create(:lecture)
      FactoryBot.create(:student_performance_rule, lecture: lecture)
      rule2 = FactoryBot.build(:student_performance_rule,
                               lecture: lecture)
      expect(rule2).to be_valid
    end

    it "allows active rules on different lectures" do
      FactoryBot.create(:student_performance_rule, :active)
      rule2 = FactoryBot.create(:student_performance_rule, :active)
      expect(rule2).to be_persisted
    end
  end
end
