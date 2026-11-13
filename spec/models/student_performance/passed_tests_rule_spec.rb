require "rails_helper"

# A rule that asks for passed tests, followed from the marking table to the
# proposal: the record is written by the computation, the evaluator reads it.
RSpec.describe("A rule that asks for passed tests") do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }
  let(:tutor) { create(:confirmed_user) }
  let!(:tests) { Array.new(3) { written_test } }
  let!(:rule) do
    create(:student_performance_rule, :active, :without_criteria,
           lecture: lecture, min_tests_passed: 2)
  end

  def written_test(passing_points: 5)
    test = create(:assignment, :expired, lecture: lecture, kind: :test,
                                         passing_points: passing_points)
    create(:assessment_task, assessment: test.assessment, max_points: 10)
    test.reload
  end

  def row_for(test)
    test.assessment.assessment_participations.find_or_create_by!(user: student)
  end

  def enter(test, points)
    Assessment::PointEntryService.enter_points(
      row_for(test), { test.assessment.tasks.first.id => points }, tutor
    )
  end

  def record
    lecture.student_performance_records.find_by(user: student)
  end

  def proposal(a_rule = rule)
    StudentPerformance::Evaluator.new(
      a_rule.reload,
      assignments_complete: lecture.reload.assignments_complete?,
      due_points: StudentPerformance::DuePoints.new(lecture: lecture),
      pass_fail_test_ids: lecture.pass_fail_test_ids
    ).evaluate(record)
  end

  before do
    create(:lecture_membership, lecture: lecture, user: student)
    lecture.update!(assignments_complete: true)
    enter(tests[0], 6)
    enter(tests[1], 4)
  end

  it "is open with one test passed, one failed and one nobody has entered" do
    expect(proposal.proposed_status).to eq(:inconclusive)
    expect(proposal.details).to include(tests_passed: 1, tests_still_open: 1)
  end

  it "admits once the third test is passed, and refuses once it is failed" do
    enter(tests[2], 5)
    expect(proposal.proposed_status).to eq(:passed)

    enter(tests[2], 4.5)
    expect(proposal.proposed_status).to eq(:failed)
    expect(proposal.missed_criteria).to eq([:tests])
  end

  it "defers all three cases again while the list is open" do
    [nil, 5, 4.5].each do |points|
      enter(tests[2], points) if points
      lecture.update!(assignments_complete: false)

      expect(proposal.proposed_status).to eq(:inconclusive)
      lecture.update!(assignments_complete: true)
    end
  end

  it "proposes the same with the test points out of the points total" do
    lecture.update!(tests_in_points_total: false)
    expect(proposal.proposed_status).to eq(:inconclusive)

    enter(tests[2], 5)
    expect(proposal.proposed_status).to eq(:passed)
  end

  it "refuses over a missed achievement, whatever the tests still allow" do
    achievement = create(:achievement, :boolean, lecture: lecture)
    create(:student_performance_rule_achievement, rule: rule, achievement: achievement)
    achievement.assessment.assessment_participations.find_or_create_by!(user: student)
               .update!(grade_text: "fail")

    expect(proposal.proposed_status).to eq(:failed)
    expect(proposal.missed_criteria).to eq([:achievements])
  end

  # The record holds the verdicts, so everything that can turn one has to
  # reach it: a corrected mark, a moved threshold, a threshold taken off.
  describe "what the record holds" do
    it "follows a mark corrected across the threshold" do
      expect(record.tests_passed_ids).to eq([tests[0].id])

      enter(tests[0], 4)

      expect(record.tests_passed_ids).to eq([])
      expect(record.tests_failed_ids).to contain_exactly(tests[0].id, tests[1].id)
    end

    it "follows a moved threshold and flags the decision taken before" do
      decision = create(:student_performance_certification, :pending,
                        lecture: lecture, user: student, rule: rule,
                        certified_at: 1.minute.ago)

      tests[1].update!(passing_points: 4)

      expect(record.tests_passed_ids).to contain_exactly(tests[0].id, tests[1].id)
      expect(StudentPerformance::Certification.stale).to include(decision)
    end

    it "drops a test whose threshold is taken off, in the record and in the count" do
      tests[0].update!(passing_points: nil)

      expect(record.tests_passed_ids).to eq([])
      expect(proposal.details).to include(tests_passed: 0, tests_still_open: 1)
    end

    it "is computed for somebody who has left the lecture as well" do
      left = StudentPerformance::ComputationService.new(lecture: lecture)
                                                   .unsaved_records_for([student]).first

      expect(left.tests_passed_among(lecture.pass_fail_test_ids)).to eq(1)
      expect(left.tests_failed_among(lecture.pass_fail_test_ids)).to eq(1)
    end
  end
end
