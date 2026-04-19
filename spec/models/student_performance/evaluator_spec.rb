require "rails_helper"

RSpec.describe(StudentPerformance::Evaluator) do
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }

  describe "#evaluate" do
    context "with a percentage-based rule" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed when percentage meets threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 60,
                                   points_max_materialized: 100,
                                   percentage_materialized: 60)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_points]).to be(true)
      end

      it "proposes :passed when percentage equals threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: 50)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
      end

      it "proposes :failed when percentage is below threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: 49.99)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
        expect(result.details[:meets_points]).to be(false)
      end

      it "proposes :failed when percentage is nil" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: nil)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
      end
    end

    context "with an absolute points rule" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_absolute_points,
                          lecture: lecture, min_points_absolute: 60)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed when points meet threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 75)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_points]).to be(true)
        expect(result.details[:required_points]).to eq(60)
      end

      it "proposes :failed when points are below threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 59)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
      end
    end

    context "with a rule that has no points threshold" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, lecture: lecture)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed regardless of points" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 0,
                                   percentage_materialized: 0)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_points]).to be(true)
      end
    end

    context "with required achievements" do
      let(:achievement1) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }
      let(:achievement2) { FactoryBot.create(:achievement, :numeric, lecture: lecture) }

      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, lecture: lecture)
      end

      before do
        FactoryBot.create(:student_performance_rule_achievement,
                          rule: rule, achievement: achievement1)
        FactoryBot.create(:student_performance_rule_achievement,
                          rule: rule, achievement: achievement2)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed when all achievements are met" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   achievements_met_ids: [achievement1.id, achievement2.id])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_achievements]).to be(true)
      end

      it "proposes :failed when some achievements are missing" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   achievements_met_ids: [achievement1.id])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
        expect(result.details[:meets_achievements]).to be(false)
      end

      it "proposes :failed when no achievements are met" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   achievements_met_ids: [])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
      end

      it "proposes :inconclusive when a required achievement is ungraded" do
        record = FactoryBot.create(
          :student_performance_record,
          lecture: lecture,
          achievements_met_ids: [achievement1.id],
          achievements_ungraded_ids: [achievement2.id]
        )

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:inconclusive)
        expect(result.details[:achievements_ungraded]).to be(true)
      end

      it "proposes :passed when all required met even if others ungraded" do
        record = FactoryBot.create(
          :student_performance_record,
          lecture: lecture,
          achievements_met_ids: [achievement1.id, achievement2.id],
          achievements_ungraded_ids: []
        )

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:achievements_ungraded]).to be(false)
      end
    end

    context "with both points and achievements required" do
      let(:achievement) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }

      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      before do
        FactoryBot.create(:student_performance_rule_achievement,
                          rule: rule, achievement: achievement)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed only when both are met" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: 60,
                                   achievements_met_ids: [achievement.id])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
      end

      it "proposes :failed when points met but achievements not" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: 60,
                                   achievements_met_ids: [])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
      end

      it "proposes :failed when achievements met but points not" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   percentage_materialized: 40,
                                   achievements_met_ids: [achievement.id])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:failed)
      end
    end

    context "when record is nil" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, lecture: lecture)
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :failed with empty details" do
        result = evaluator.evaluate(nil)
        expect(result.proposed_status).to eq(:failed)
        expect(result.details).to eq({})
      end
    end

    it "includes all expected detail keys" do
      rule = FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                               lecture: lecture, min_percentage: 50)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture, percentage_materialized: 60)

      result = described_class.new(rule).evaluate(record)
      expected_keys = [:meets_points, :meets_achievements,
                       :achievements_ungraded, :points_total, :points_max,
                       :percentage, :required_points, :required_percentage,
                       :achievement_ids_met, :achievement_ids_ungraded,
                       :achievement_ids_required]
      expect(result.details.keys).to match_array(expected_keys)
    end
  end

  describe "#bulk_evaluate" do
    let(:rule) do
      FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                        lecture: lecture, min_percentage: 50)
    end

    let(:evaluator) { described_class.new(rule) }

    let!(:passing_record) do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, percentage_materialized: 80)
    end

    let!(:failing_record) do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, percentage_materialized: 30)
    end

    it "returns a hash mapping records to results" do
      results = evaluator.bulk_evaluate([passing_record, failing_record])

      expect(results.keys).to match_array([passing_record, failing_record])
      expect(results[passing_record].proposed_status).to eq(:passed)
      expect(results[failing_record].proposed_status).to eq(:failed)
    end
  end
end
