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
      # A rule must constrain something, so a threshold-less rule carries an
      # achievement instead; points are then irrelevant to the outcome.
      let(:achievement) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }

      let(:rule) do
        FactoryBot.build(:student_performance_rule, :active, :without_criteria,
                         lecture: lecture).tap do |r|
          r.rule_achievements.build(achievement: achievement, position: 1)
          r.save!
        end
      end

      let(:evaluator) { described_class.new(rule) }

      it "proposes :passed regardless of points" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 0,
                                   percentage_materialized: 0,
                                   achievements_met_ids: [achievement.id])

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_points]).to be(true)
      end
    end

    context "with required achievements" do
      let(:achievement1) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }
      let(:achievement2) { FactoryBot.create(:achievement, :numeric, lecture: lecture) }

      let(:rule) do
        FactoryBot.build(:student_performance_rule, :active, :without_criteria,
                         lecture: lecture).tap do |r|
          r.rule_achievements.build(achievement: achievement1, position: 1)
          r.rule_achievements.build(achievement: achievement2, position: 2)
          r.save!
        end
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

    # A student below the threshold may still be above it once their tutor
    # finishes. Deciding now would refuse eligibility for somebody else's
    # backlog — but only where the outstanding points could actually change the
    # answer, otherwise nobody could be judged while any marking is open.
    context "with marking still outstanding" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      let(:evaluator) { described_class.new(rule) }

      def record_with(total:, pending:)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture,
                          points_total_materialized: total,
                          points_max_materialized: 120,
                          points_max_pending_materialized: pending,
                          percentage_materialized: (total / 120.0 * 100).round(2))
      end

      it "proposes :passed when the threshold is already cleared" do
        result = evaluator.evaluate(record_with(total: 70, pending: 10))

        expect(result.proposed_status).to eq(:passed)
      end

      it "proposes :inconclusive when the outstanding points could still reach it" do
        result = evaluator.evaluate(record_with(total: 55, pending: 10))

        expect(result.proposed_status).to eq(:inconclusive)
        expect(result.details[:points_pending]).to be(true)
      end

      it "proposes :failed when even all outstanding points fall short" do
        result = evaluator.evaluate(record_with(total: 20, pending: 10))

        expect(result.proposed_status).to eq(:failed)
      end

      it "proposes :failed below the threshold with nothing outstanding" do
        result = evaluator.evaluate(record_with(total: 55, pending: 0))

        expect(result.proposed_status).to eq(:failed)
      end

      it "decides on exactly the reachable boundary" do
        # 50 % of 120 is 60, so 50 + 10 lands precisely on it.
        result = evaluator.evaluate(record_with(total: 50, pending: 10))

        expect(result.proposed_status).to eq(:inconclusive)
      end

      context "with an absolute threshold" do
        let(:rule) do
          FactoryBot.create(:student_performance_rule, :active, :with_absolute_points,
                            lecture: lecture, min_points_absolute: 60)
        end

        it "proposes :inconclusive when the outstanding points could still reach it" do
          result = evaluator.evaluate(record_with(total: 55, pending: 10))

          expect(result.proposed_status).to eq(:inconclusive)
        end

        it "proposes :failed when they cannot" do
          result = evaluator.evaluate(record_with(total: 20, pending: 10))

          expect(result.proposed_status).to eq(:failed)
        end
      end

      # Being exempt from everything is not the same as having earned nothing:
      # the threshold has nothing left to measure, so a person has to decide.
      context "when there is nothing to measure" do
        it "defers rather than failing a student with no maximum at all" do
          record = FactoryBot.create(:student_performance_record,
                                     lecture: lecture,
                                     points_total_materialized: 0,
                                     points_max_materialized: 0,
                                     points_max_pending_materialized: 0,
                                     percentage_materialized: nil)

          result = evaluator.evaluate(record)

          expect(result.proposed_status).to eq(:inconclusive)
        end

        it "still fails a student who could have earned something" do
          record = FactoryBot.create(:student_performance_record,
                                     lecture: lecture,
                                     points_total_materialized: 0,
                                     points_max_materialized: 120,
                                     points_max_pending_materialized: 0,
                                     percentage_materialized: 0)

          result = evaluator.evaluate(record)

          expect(result.proposed_status).to eq(:failed)
        end

        context "under an absolute threshold" do
          let(:rule) do
            FactoryBot.create(:student_performance_rule, :active, :with_absolute_points,
                              lecture: lecture, min_points_absolute: 60)
          end

          it "defers there too" do
            record = FactoryBot.create(:student_performance_record,
                                       lecture: lecture,
                                       points_total_materialized: 0,
                                       points_max_materialized: 0,
                                       percentage_materialized: nil)

            result = evaluator.evaluate(record)

            expect(result.proposed_status).to eq(:inconclusive)
          end
        end

        # A rule has to constrain something, so "no points threshold" means it
        # asks for an achievement instead — and then a zero maximum is no
        # obstacle, because points were never part of the question.
        context "under a rule that only asks for an achievement" do
          let(:achievement) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }
          let(:rule) do
            FactoryBot.build(:student_performance_rule, :active, :without_criteria,
                             lecture: lecture).tap do |r|
              r.rule_achievements.build(achievement: achievement, position: 1)
              r.save!
            end
          end

          it "passes, since points were never asked for" do
            record = FactoryBot.create(:student_performance_record,
                                       lecture: lecture,
                                       points_total_materialized: 0,
                                       points_max_materialized: 0,
                                       percentage_materialized: nil,
                                       achievements_met_ids: [achievement.id])

            result = evaluator.evaluate(record)

            expect(result.proposed_status).to eq(:passed)
          end
        end
      end

      context "when an achievement is missing outright" do
        let(:achievement) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }

        before do
          FactoryBot.create(:student_performance_rule_achievement,
                            rule: rule, achievement: achievement)
        end

        # Nothing a tutor enters can supply a missing achievement, so the answer
        # is settled even though points are still moving.
        it "proposes :failed rather than deferring" do
          result = evaluator.evaluate(record_with(total: 55, pending: 10))

          expect(result.proposed_status).to eq(:failed)
        end
      end
    end

    context "when record is nil" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, lecture: lecture)
      end

      let(:evaluator) { described_class.new(rule) }

      # Answering "failed" would refuse a student their exam on the strength of
      # a record nobody has written yet.
      it "refuses to judge instead of proposing a status" do
        expect { evaluator.evaluate(nil) }
          .to raise_error(ArgumentError, /no performance record/)
      end
    end

    it "includes all expected detail keys" do
      rule = FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                               lecture: lecture, min_percentage: 50)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture, percentage_materialized: 60)

      result = described_class.new(rule).evaluate(record)
      expected_keys = [:meets_points, :points_pending, :meets_achievements,
                       :achievements_ungraded, :points_total, :points_max,
                       :points_max_pending, :percentage, :required_points,
                       :required_percentage, :achievement_ids_met,
                       :achievement_ids_ungraded, :achievement_ids_required]
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
