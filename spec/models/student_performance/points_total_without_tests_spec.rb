require "rails_helper"

# The points total is worked out in four places: the record, DuePoints, the
# hand-ins hub and the dashboard bar. They have to tell one student the same
# thing, with the tests in the total and with them out.
RSpec.describe("The points total with tests kept out of it") do
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:student) { create(:confirmed_user) }

  def assignment(max, kind: :homework, deadline: 1.week.ago)
    created = create(:assignment, lecture: lecture, kind: kind,
                                  deadline: 1.year.from_now)
    created.update_column(:deadline, deadline) # rubocop:disable Rails/SkipsModelValidations
    create(:assessment_task, assessment: created.assessment, max_points: max)
    created.reload
  end

  def review(assignment, points)
    row = create(:assessment_participation, :reviewed, assessment: assignment.assessment,
                                                       user: student)
    create(:assessment_task_point, task: assignment.assessment.tasks.first,
                                   assessment_participation: row, points: points)
  end

  def record
    StudentPerformance::ComputationService.new(lecture: lecture)
                                          .compute_and_upsert_record_for(student)
    lecture.student_performance_records.find_by(user: student)
  end

  def due_points
    StudentPerformance::DuePoints.new(lecture: lecture)
  end

  def standing
    Assessment::SubmissionsHub::Loader.new(lecture: lecture, user: student).call.standing
  end

  def bar
    DashboardPointsProgressComponent.new(lecture: lecture, user: student)
  end

  # What each place gives as points, the maximum settled so far, and the share.
  def figures
    current = record
    { record: [current.points_total_materialized, current.points_max_materialized],
      due_points: [due_points.marked_max_for(student.id),
                   due_points.marked_percentage_for(current)],
      hub: [standing.points_marked_so_far, standing.percentage],
      bar: [bar.points, bar.max_points, bar.percentage] }
  end

  before do
    create(:lecture_membership, lecture: lecture, user: student)
    review(assignment(20), 12)
    create(:assessment_participation, :exempt, assessment: assignment(10).assessment,
                                               user: student)
    assignment(20, deadline: 2.weeks.from_now)
    review(assignment(10, kind: :test), 4)
  end

  it "counts the test everywhere while the lecture says nothing" do
    expect(figures).to eq(record: [16, 50], due_points: [30, 53.33],
                          hub: [30, 53.33], bar: [16, 30, 53])
    expect(standing.tests_apart).to be(false)
    expect(standing.test_points_marked_so_far).to be_nil
  end

  context "with the tests out of the total" do
    before { lecture.update!(tests_in_points_total: false) }

    let(:homework_alone) do
      { record: [12, 40], due_points: [20, 60], hub: [20, 60], bar: [12, 20, 60] }
    end

    it "gives the homework's figures in every place, and the tests' beside them" do
      expect(figures).to eq(homework_alone)
      expect(standing.test_points_total).to eq(4)
      expect(standing.test_points_marked_so_far).to eq(10)
    end

    it "is not moved by a test marked in its week whose deadline is then moved on" do
      early = assignment(10, kind: :test, deadline: Time.zone.now.end_of_week)
      review(early, 5)
      early.update_column(:deadline, 2.weeks.from_now.end_of_week) # rubocop:disable Rails/SkipsModelValidations

      expect(figures).to eq(homework_alone)
      expect(standing.test_points_total).to eq(9)
      expect(standing.test_points_marked_so_far).to eq(20)
    end

    it "is not moved by a test nobody has entered anything on" do
      assignment(10, kind: :test)

      expect(figures).to eq(homework_alone)
      expect(standing.points_awaiting_marks).to eq(0)
      expect(standing.test_points_marked_so_far).to eq(10)
    end

    it "waits for no test, also not one the student is exempt from" do
      coming = assignment(10, kind: :test, deadline: 2.weeks.from_now.end_of_week)
      create(:assessment_participation, :exempt, assessment: coming.assessment,
                                                 user: student)
      rule = create(:student_performance_rule, :active, :with_percentage,
                    lecture: lecture, min_percentage: 50)

      result = StudentPerformance::Evaluator
               .new(rule, assignments_complete: true, due_points: due_points)
               .evaluate(record)

      expect(result.details).to include(not_due_sheets: 1, not_due_tests: 0)
    end
  end
end
