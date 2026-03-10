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

  describe "#student_met_threshold?" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    before do
      Flipper.enable(:assessment_grading)
      FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
    end

    after { Flipper.disable(:assessment_grading) }

    context "when boolean" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "returns true when grade_text is 'pass'" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "pass")
        expect(achievement.student_met_threshold?(user)).to be(true)
      end

      it "returns false when grade_text is 'fail'" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "fail")
        expect(achievement.student_met_threshold?(user)).to be(false)
      end
    end

    context "when numeric" do
      let(:achievement) do
        FactoryBot.create(:achievement, :numeric, lecture: lecture)
      end

      it "returns true when grade_text meets threshold" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "12")
        expect(achievement.student_met_threshold?(user)).to be(true)
      end

      it "returns false when grade_text is below threshold" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "5")
        expect(achievement.student_met_threshold?(user)).to be(false)
      end
    end

    context "when percentage" do
      let(:achievement) do
        FactoryBot.create(:achievement, :percentage, lecture: lecture)
      end

      it "returns true when grade_text meets threshold" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "80.0")
        expect(achievement.student_met_threshold?(user)).to be(true)
      end

      it "returns false when grade_text is below threshold" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)
        participation.update!(grade_text: "50.0")
        expect(achievement.student_met_threshold?(user)).to be(false)
      end
    end

    context "when grade_text is blank" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "returns false" do
        expect(achievement.student_met_threshold?(user)).to be(false)
      end
    end

    context "when no participation exists" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end
      let(:other_user) { FactoryBot.create(:confirmed_user) }

      it "returns false" do
        expect(achievement.student_met_threshold?(other_user)).to be(false)
      end
    end

    context "when no assessment exists" do
      let(:achievement) do
        Flipper.disable(:assessment_grading)
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "returns false" do
        expect(achievement.student_met_threshold?(user)).to be(false)
      end
    end
  end

  describe "assessable wiring" do
    before { Flipper.enable(:assessment_grading) }

    after { Flipper.disable(:assessment_grading) }

    it "creates an assessment on create" do
      achievement = FactoryBot.create(:achievement)
      expect(achievement.assessment).to be_present
      expect(achievement.assessment).to be_a(Assessment::Assessment)
    end

    it "configures assessment without points or submission" do
      achievement = FactoryBot.create(:achievement)
      assessment = achievement.assessment
      expect(assessment.requires_points).to be(false)
      expect(assessment.requires_submission).to be(false)
    end

    it "seeds participations from lecture members" do
      lecture = FactoryBot.create(:lecture)
      users = FactoryBot.create_list(:user, 3)
      users.each do |user|
        FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
      end
      achievement = FactoryBot.create(:achievement, lecture: lecture)
      expect(achievement.assessment.assessment_participations.count).to eq(3)
    end

    it "does not create assessment when flag is disabled" do
      Flipper.disable(:assessment_grading)
      achievement = FactoryBot.create(:achievement)
      expect(achievement.assessment).to be_nil
    end
  end
end
