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
      rule = FactoryBot.build(:student_performance_rule, :with_absolute_points)
      expect(rule.min_percentage).to be_nil
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
      rule = FactoryBot.build(:student_performance_rule, :with_absolute_points)
      expect(rule).to be_valid
    end

    it "rejects a threshold value that contradicts the mode" do
      rule = FactoryBot.build(:student_performance_rule, :without_criteria,
                              min_points_absolute: 60)

      expect(rule).not_to be_valid
      expect(rule.errors.added?(:base, :threshold_without_mode)).to be(true)
    end

    it "rejects a percentage mode without a percentage value" do
      rule = FactoryBot.build(:student_performance_rule, min_percentage: nil)

      expect(rule).not_to be_valid
      expect(rule.errors.added?(:min_percentage, :blank)).to be(true)
    end

    describe "at least one criterion" do
      it "rejects a rule with neither a threshold nor an achievement" do
        rule = FactoryBot.build(:student_performance_rule, :without_criteria)

        expect(rule).not_to be_valid
        expect(rule.errors.added?(:base, :no_criteria)).to be(true)
      end

      it "accepts a threshold without any achievement" do
        rule = FactoryBot.build(:student_performance_rule, :with_percentage)
        expect(rule).to be_valid
      end

      it "accepts an achievement without any threshold" do
        lecture = FactoryBot.create(:lecture)
        rule = FactoryBot.build(:student_performance_rule, :without_criteria,
                                lecture: lecture)
        achievement = FactoryBot.create(:achievement, lecture: lecture)
        rule.rule_achievements.build(achievement: achievement, position: 1)

        expect(rule).to be_valid
      end

      it "rejects removing the last achievement from a threshold-less rule" do
        lecture = FactoryBot.create(:lecture)
        rule = FactoryBot.build(:student_performance_rule, :without_criteria,
                                lecture: lecture)
        achievement = FactoryBot.create(:achievement, lecture: lecture)
        rule.rule_achievements.build(achievement: achievement, position: 1)
        rule.save!

        rule.rule_achievements.each(&:mark_for_destruction)

        expect(rule).not_to be_valid
        expect(rule.errors.added?(:base, :no_criteria)).to be(true)
      end
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

  # The mark on the student's bar: what this rule asks of them in points.
  describe "#required_points" do
    let(:lecture) { FactoryBot.create(:lecture) }

    def record_with(max)
      FactoryBot.build(:student_performance_record,
                       points_max_materialized: max)
    end

    it "takes the percentage of what the lecture is worth" do
      rule = FactoryBot.build(:student_performance_rule, :with_percentage,
                              lecture: lecture, min_percentage: 50)

      expect(rule.required_points(record_with(176))).to eq(88)
    end

    it "hands an absolute threshold back as it stands" do
      rule = FactoryBot.build(:student_performance_rule, :with_absolute_points,
                              lecture: lecture, min_points_absolute: 90)

      expect(rule.required_points(record_with(176))).to eq(90)
    end

    it "asks for nothing where the rule sets no threshold" do
      achievement = FactoryBot.create(:achievement, lecture: lecture)
      rule = FactoryBot.build(:student_performance_rule, :without_criteria,
                              lecture: lecture,
                              required_achievements: [achievement])

      expect(rule.required_points(record_with(176))).to be_nil
    end

    # A percentage of nothing is not a threshold, and a bar drawn against it
    # would claim a ratio that does not exist.
    it "is nil for a percentage of a lecture that is worth no points" do
      rule = FactoryBot.build(:student_performance_rule, :with_percentage,
                              lecture: lecture, min_percentage: 50)

      expect(rule.required_points(record_with(0))).to be_nil
    end

    it "is nil for a percentage without a record to weigh" do
      rule = FactoryBot.build(:student_performance_rule, :with_percentage,
                              lecture: lecture, min_percentage: 50)

      expect(rule.required_points(nil)).to be_nil
    end

    # An absolute threshold stands on its own; it needs no scale.
    it "keeps an absolute threshold even without a record" do
      rule = FactoryBot.build(:student_performance_rule, :with_absolute_points,
                              lecture: lecture, min_points_absolute: 90)

      expect(rule.required_points(nil)).to eq(90)
    end
  end
end
