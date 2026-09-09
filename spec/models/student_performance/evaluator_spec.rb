require "rails_helper"

RSpec.describe(StudentPerformance::Evaluator) do
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }

  describe "#evaluate" do
    context "with a percentage-based rule" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

      it "proposes :passed when points meet threshold" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 75)

        result = evaluator.evaluate(record)
        expect(result.proposed_status).to eq(:passed)
        expect(result.details[:meets_points]).to be(true)
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

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

    # A sheet with a deadline still to come has been asked of nobody. Judging
    # a student on it means failing them for a term that is not over.
    context "with sheets that are not due yet" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      let(:evaluator) do
        described_class.new(
          rule,
          assignments_complete: true,
          due_points: StudentPerformance::DuePoints.new(lecture: lecture)
        )
      end

      let(:student) { FactoryBot.create(:confirmed_user) }

      def sheet(deadline:, points:)
        assignment = FactoryBot.create(:assignment, lecture: lecture)
        # rubocop:disable Rails/SkipsModelValidations
        assignment.update_column(:deadline, deadline)
        # rubocop:enable Rails/SkipsModelValidations
        assessment = assignment.assessment
        FactoryBot.create(:assessment_task, assessment: assessment,
                                            max_points: points)
        assessment.reload
      end

      def record_with(total:, max:, pending: 0)
        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: student,
                          points_total_materialized: total,
                          points_max_materialized: max,
                          points_max_pending_materialized: pending,
                          percentage_materialized: (total / max.to_f * 100).round(2))
      end

      it "defers instead of failing a student who has the term ahead of them" do
        sheet(deadline: 2.days.ago, points: 20)
        sheet(deadline: 3.days.from_now, points: 100)

        result = evaluator.evaluate(record_with(total: 5, max: 120))

        expect(result.proposed_status).to eq(:inconclusive)
        expect(result.details[:points_not_due]).to be(true)
      end

      it "names the sheets to come rather than a marking backlog" do
        sheet(deadline: 2.days.ago, points: 20)
        sheet(deadline: 3.days.from_now, points: 100)

        result = evaluator.evaluate(record_with(total: 5, max: 120))

        expect(result.verdict_deferral_reasons).to eq([:points_not_due])
      end

      it "still fails a student the remaining sheets cannot carry" do
        sheet(deadline: 2.days.ago, points: 100)
        sheet(deadline: 3.days.from_now, points: 20)

        result = evaluator.evaluate(record_with(total: 5, max: 120))

        expect(result.proposed_status).to eq(:failed)
      end

      # The early hand-in is in `points_max_pending_materialized` and in the
      # sheets still to come; counted twice it would lift the best case over
      # the threshold and defer a settled case.
      it "counts an early hand-in once" do
        sheet(deadline: 2.days.ago, points: 100)
        early = sheet(deadline: 3.days.from_now, points: 20)
        FactoryBot.create(:assessment_participation, :submitted,
                          assessment: early, user: student)

        result = evaluator.evaluate(record_with(total: 25, max: 120,
                                                pending: 20))

        expect(result.proposed_status).to eq(:failed)
      end
    end

    # While sheets can still be added, another one worth p points raises the
    # points needed by p/2 and the points reachable by p — so it can overturn a
    # pass and a fail alike, and neither is worth handing out.
    context "while the list of assignments is open" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                          lecture: lecture, min_percentage: 50)
      end

      let(:evaluator) { described_class.new(rule, assignments_complete: false) }

      it "defers a student who clears the threshold today" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 90,
                                   points_max_materialized: 100,
                                   percentage_materialized: 90)

        expect(evaluator.evaluate(record).proposed_status).to eq(:inconclusive)
      end

      it "defers a student nothing outstanding could carry" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 5,
                                   points_max_materialized: 100,
                                   points_max_pending_materialized: 0,
                                   percentage_materialized: 5)

        expect(evaluator.evaluate(record).proposed_status).to eq(:inconclusive)
      end

      # The other reasons are true as well; this is the one holding the verdict,
      # and repeating the rest in every row of the table says nothing.
      it "gives one reason, and it is not about a single sheet" do
        record = FactoryBot.create(:student_performance_record,
                                   lecture: lecture,
                                   points_total_materialized: 5,
                                   points_max_materialized: 100,
                                   points_max_pending_materialized: 40,
                                   percentage_materialized: 5)

        result = evaluator.evaluate(record)

        expect(result.verdict_deferral_reasons).to eq([:assignments_incomplete])
        expect(result.details[:assignments_incomplete]).to be(true)
      end
    end

    context "when record is nil" do
      let(:rule) do
        FactoryBot.create(:student_performance_rule, :active, lecture: lecture)
      end

      let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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

      result = described_class.new(rule, assignments_complete: true).evaluate(record)
      expected_keys = [:assignments_incomplete, :meets_points, :points_not_due,
                       :points_pending, :points_not_measurable,
                       :meets_achievements, :achievements_ungraded]
      expect(result.details.keys).to match_array(expected_keys)
    end
  end

  describe "a threshold of zero" do
    it "passes a student with nothing to measure, since points were not asked" do
      lecture = FactoryBot.create(:lecture)
      rule = FactoryBot.create(:student_performance_rule, :active,
                               :with_percentage,
                               lecture: lecture, min_percentage: 0)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 0,
                                 points_max_materialized: 0,
                                 percentage_materialized: 0)

      result = described_class.new(rule, assignments_complete: true).evaluate(record)
      expect(result.proposed_status).to eq(:passed)
      expect(result.points_criterion_deferral).to be_nil
    end
  end

  describe "Result#missed_criteria" do
    let(:achievement) { FactoryBot.create(:achievement, lecture: lecture) }

    let(:rule) do
      FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                        lecture: lecture, min_percentage: 50)
    end

    let(:evaluator) { described_class.new(rule, assignments_complete: true) }

    before do
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
    end

    it "names the criterion that settled the case" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 percentage_materialized: 30,
                                 achievements_met_ids: [achievement.id])

      expect(evaluator.evaluate(record).missed_criteria).to eq([:points])
    end

    it "does not blame a criterion that is merely open" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 percentage_materialized: 30,
                                 achievements_ungraded_ids: [achievement.id])

      expect(evaluator.evaluate(record).missed_criteria).to eq([:points])
    end

    it "names both when both are missed" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 percentage_materialized: 30)

      expect(evaluator.evaluate(record).missed_criteria)
        .to eq([:points, :achievements])
    end

    it "stays silent unless the proposal is a fail" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 60,
                                 points_max_materialized: 100,
                                 percentage_materialized: 60,
                                 achievements_ungraded_ids: [achievement.id])

      expect(evaluator.evaluate(record).missed_criteria).to eq([])
    end
  end

  describe "Result#verdict_deferral_reasons" do
    let(:rule) do
      FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                        lecture: lecture, min_percentage: 50)
    end

    let(:evaluator) { described_class.new(rule, assignments_complete: true) }

    it "names the outstanding marking that could still carry the student" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 points_max_pending_materialized: 40,
                                 percentage_materialized: 30)

      expect(evaluator.evaluate(record).verdict_deferral_reasons)
        .to eq([:points_pending])
    end

    it "names a maximum of zero as its own reason" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 0,
                                 points_max_materialized: 0,
                                 percentage_materialized: 0)

      expect(evaluator.evaluate(record).verdict_deferral_reasons)
        .to eq([:points_not_measurable])
    end

    it "names both criteria when both are open" do
      achievement = FactoryBot.create(:achievement, lecture: lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 points_max_pending_materialized: 40,
                                 percentage_materialized: 30,
                                 achievements_ungraded_ids: [achievement.id])

      expect(evaluator.evaluate(record).verdict_deferral_reasons)
        .to eq([:points_pending, :achievements_ungraded])
    end

    it "stays silent on a decided proposal" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 60,
                                 points_max_materialized: 100,
                                 percentage_materialized: 60)

      expect(evaluator.evaluate(record).verdict_deferral_reasons).to be_empty
    end

    it "reads the points criterion even when another one settles the case" do
      achievement = FactoryBot.create(:achievement, lecture: lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 points_max_pending_materialized: 40,
                                 percentage_materialized: 30)

      result = evaluator.evaluate(record)
      expect(result.proposed_status).to eq(:failed)
      expect(result.verdict_deferral_reasons).to be_empty
      expect(result.points_criterion_deferral).to eq(:points_pending)
    end

    it "leaves the points criterion silent once it is settled" do
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 percentage_materialized: 30)

      expect(evaluator.evaluate(record).points_criterion_deferral).to be_nil
    end

    it "stays silent when a missed criterion settles an otherwise open case" do
      achievement = FactoryBot.create(:achievement, lecture: lecture)
      FactoryBot.create(:student_performance_rule_achievement,
                        rule: rule, achievement: achievement)
      record = FactoryBot.create(:student_performance_record,
                                 lecture: lecture,
                                 points_total_materialized: 30,
                                 points_max_materialized: 100,
                                 percentage_materialized: 30,
                                 achievements_ungraded_ids: [achievement.id])

      result = evaluator.evaluate(record)
      expect(result.proposed_status).to eq(:failed)
      expect(result.details[:achievements_ungraded]).to be(true)
      expect(result.verdict_deferral_reasons).to be_empty
    end
  end

  describe "#bulk_evaluate" do
    let(:rule) do
      FactoryBot.create(:student_performance_rule, :active, :with_percentage,
                        lecture: lecture, min_percentage: 50)
    end

    let(:evaluator) { described_class.new(rule, assignments_complete: true) }

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
