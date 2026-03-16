require "rails_helper"

RSpec.describe(StudentPerformance::RuleAchievement, type: :model) do
  describe "factory" do
    it "creates a valid rule_achievement" do
      rule_achievement = FactoryBot.create(
        :student_performance_rule_achievement
      )
      expect(rule_achievement).to be_valid
      expect(rule_achievement.position).to eq(1)
    end
  end

  describe "associations" do
    it "belongs to a rule" do
      rule_achievement = FactoryBot.build(
        :student_performance_rule_achievement, rule: nil
      )
      expect(rule_achievement).not_to be_valid
    end

    it "belongs to an achievement" do
      rule_achievement = FactoryBot.build(
        :student_performance_rule_achievement, achievement: nil
      )
      expect(rule_achievement).not_to be_valid
    end
  end

  describe "validations" do
    it "enforces uniqueness of rule/achievement pair" do
      existing = FactoryBot.create(:student_performance_rule_achievement)
      duplicate = FactoryBot.build(
        :student_performance_rule_achievement,
        rule: existing.rule,
        achievement: existing.achievement
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:rule_id]).to be_present
    end

    it "requires position" do
      rule_achievement = FactoryBot.build(
        :student_performance_rule_achievement, position: nil
      )
      expect(rule_achievement).not_to be_valid
    end

    it "rejects achievement from a different lecture" do
      rule = FactoryBot.create(:student_performance_rule)
      other_achievement = FactoryBot.create(:achievement)
      ra = FactoryBot.build(
        :student_performance_rule_achievement,
        rule: rule,
        achievement: other_achievement
      )
      expect(ra).not_to be_valid
      expect(ra.errors[:achievement]).to be_present
    end

    it "accepts achievement from the same lecture" do
      rule = FactoryBot.create(:student_performance_rule)
      achievement = FactoryBot.create(:achievement,
                                      lecture: rule.lecture)
      ra = FactoryBot.build(
        :student_performance_rule_achievement,
        rule: rule,
        achievement: achievement
      )
      expect(ra).to be_valid
    end
  end

  describe "acts_as_list" do
    it "manages position scoped to rule" do
      rule = FactoryBot.create(:student_performance_rule)
      a1 = FactoryBot.create(:achievement, lecture: rule.lecture)
      a2 = FactoryBot.create(:achievement, lecture: rule.lecture,
                                           title: "Second Achievement")

      ra1 = FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: a1)
      ra2 = FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule, achievement: a2)
      positions = [ra1, ra2].map { |ra| ra.reload.position }
      expect(positions.uniq.size).to eq(2)
    end

    it "scopes position to rule" do
      rule1 = FactoryBot.create(:student_performance_rule)
      rule2 = FactoryBot.create(:student_performance_rule)
      achievement = FactoryBot.create(:achievement,
                                      lecture: rule1.lecture)

      ra1 = FactoryBot.create(:student_performance_rule_achievement,
                              rule: rule1, achievement: achievement)
      ra2 = FactoryBot.create(
        :student_performance_rule_achievement,
        rule: rule2,
        achievement: FactoryBot.create(:achievement,
                                       lecture: rule2.lecture)
      )
      expect(ra1.position).to eq(1)
      expect(ra2.position).to eq(1)
    end
  end
end
