require "rails_helper"

RSpec.describe(StudentPerformance::ComputationService) do
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }
  let(:user) { FactoryBot.create(:confirmed_user) }

  before do
    FactoryBot.create(:lecture_membership, user: user, lecture: lecture)
  end

  describe "#compute_and_upsert_record_for" do
    subject(:compute) { described_class.new(lecture: lecture).compute_and_upsert_record_for(user) }

    context "when user has no assessment participations" do
      it "creates a record with zero points" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_total_materialized).to eq(0)
      end

      it "sets points_max to zero when no assessments exist" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(0)
      end

      it "sets percentage to nil when points_max is zero" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.percentage_materialized).to be_nil
      end

      it "sets empty achievements_met_ids" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.achievements_met_ids).to eq([])
      end
    end

    context "when user has participations with task points" do
      let(:assignment) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assessment) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment,
                                                     lecture: lecture)
      end

      let!(:task1) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10) }
      let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 20) }

      let!(:participation) do
        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment, user: user)
      end

      let!(:tp1) do
        FactoryBot.create(:assessment_task_point, task: task1,
                                                  assessment_participation: participation,
                                                  points: 8)
      end

      let!(:tp2) do
        FactoryBot.create(:assessment_task_point, task: task2,
                                                  assessment_participation: participation,
                                                  points: 15)
      end

      it "aggregates points_total from task points" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_total_materialized).to eq(23)
      end

      it "computes points_max from task max_points" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(30)
      end

      it "computes percentage correctly" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.percentage_materialized).to eq(76.67)
      end

      it "sets computed_at" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.computed_at).to be_within(1.second).of(Time.current)
      end
    end

    context "with multiple assessments" do
      let(:assignment1) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment2) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      let!(:task_a) { FactoryBot.create(:assessment_task, assessment: assessment1, max_points: 10) }
      let!(:task_b) { FactoryBot.create(:assessment_task, assessment: assessment2, max_points: 40) }

      let!(:participation1) do
        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
      end

      let!(:participation2) do
        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment2, user: user)
      end

      let!(:tp_a) do
        FactoryBot.create(:assessment_task_point, task: task_a,
                                                  assessment_participation: participation1,
                                                  points: 7)
      end

      let!(:tp_b) do
        FactoryBot.create(:assessment_task_point, task: task_b,
                                                  assessment_participation: participation2,
                                                  points: 30)
      end

      it "sums points across all assessments" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_total_materialized).to eq(37)
        expect(record.points_max_materialized).to eq(50)
        expect(record.percentage_materialized).to eq(74.0)
      end
    end

    context "when called twice (upsert)" do
      let(:assignment) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assessment) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment, lecture: lecture)
      end

      let!(:task1) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10) }
      let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 20) }

      let!(:participation) do
        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment, user: user)
      end

      it "updates the existing record instead of creating a duplicate" do
        FactoryBot.create(:assessment_task_point, task: task1,
                                                  assessment_participation: participation,
                                                  points: 5)

        described_class.new(lecture: lecture).compute_and_upsert_record_for(user)
        expect(StudentPerformance::Record.where(lecture: lecture, user: user).count).to eq(1)

        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_total_materialized).to eq(5)

        FactoryBot.create(:assessment_task_point, task: task2,
                                                  assessment_participation: participation,
                                                  points: 13)

        described_class.new(lecture: lecture).compute_and_upsert_record_for(user)
        expect(StudentPerformance::Record.where(lecture: lecture, user: user).count).to eq(1)

        record.reload
        expect(record.points_total_materialized).to eq(18)
      end
    end

    context "when assessment has total_points override" do
      let(:assignment) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assessment) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment,
                                                     lecture: lecture, total_points: 50)
      end

      let!(:task) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10) }

      it "uses effective_total_points for points_max" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(50)
      end
    end

    context "when participation is pending" do
      let(:assignment) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assessment) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment,
                                                     lecture: lecture)
      end

      let!(:task) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 10) }

      let!(:participation) do
        FactoryBot.create(:assessment_participation, :pending,
                          assessment: assessment, user: user)
      end

      let!(:tp) do
        FactoryBot.create(:assessment_task_point, task: task,
                                                  assessment_participation: participation,
                                                  points: 8)
      end

      it "excludes pending task points from points_total" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_total_materialized).to eq(0)
      end

      it "still includes the assessment in points_max" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(10)
      end
    end

    context "when participation is exempt" do
      let(:assignment1) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment2) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      let!(:task1) { FactoryBot.create(:assessment_task, assessment: assessment1, max_points: 20) }
      let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment2, max_points: 30) }

      let!(:reviewed_participation) do
        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
      end

      let!(:exempt_participation) do
        FactoryBot.create(:assessment_participation, :exempt,
                          assessment: assessment2, user: user)
      end

      let!(:tp) do
        FactoryBot.create(:assessment_task_point, task: task1,
                                                  assessment_participation: reviewed_participation,
                                                  points: 15)
      end

      it "excludes exempt assessment from points_max" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(20)
      end

      it "computes percentage without the exempt assessment" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.percentage_materialized).to eq(75.0)
      end
    end

    context "assessment counts" do
      let(:assignment1) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment2) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment3) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      let(:assessment3) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment3,
                                                     lecture: lecture)
      end

      before do
        FactoryBot.create(:assessment_task, assessment: assessment1, max_points: 10)
        FactoryBot.create(:assessment_task, assessment: assessment2, max_points: 10)
        FactoryBot.create(:assessment_task, assessment: assessment3, max_points: 10)

        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
        FactoryBot.create(:assessment_participation, :pending,
                          assessment: assessment2, user: user)
        FactoryBot.create(:assessment_participation, :exempt,
                          assessment: assessment3, user: user)
      end

      it "stores all assessment counts" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.assessments_total_count).to eq(3)
        expect(record.assessments_reviewed_count).to eq(1)
        expect(record.assessments_pending_grading_count).to eq(1)
        expect(record.assessments_not_submitted_count).to eq(0)
        expect(record.assessments_exempt_count).to eq(1)
      end
    end

    context "when pending participation has no submitted_at" do
      let(:assignment1) do
        FactoryBot.create(:assignment, :with_lecture, lecture: lecture)
      end

      let(:assignment2) do
        FactoryBot.create(:assignment, :with_lecture, lecture: lecture)
      end

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      before do
        FactoryBot.create(:assessment_task,
                          assessment: assessment1, max_points: 10)
        FactoryBot.create(:assessment_task,
                          assessment: assessment2, max_points: 10)

        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
        FactoryBot.create(:assessment_participation,
                          assessment: assessment2, user: user,
                          status: :pending, submitted_at: nil)
      end

      it "counts it as not submitted rather than pending grading" do
        compute
        record = StudentPerformance::Record.find_by(
          lecture: lecture, user: user
        )
        expect(record.assessments_pending_grading_count).to eq(0)
        expect(record.assessments_not_submitted_count).to eq(1)
      end
    end

    context "when assessment has no participation record" do
      let(:assignment1) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment2) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      before do
        FactoryBot.create(:assessment_task, assessment: assessment1, max_points: 10)
        FactoryBot.create(:assessment_task, assessment: assessment2, max_points: 20)

        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
      end

      it "counts the missing participation as not submitted" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.assessments_total_count).to eq(2)
        expect(record.assessments_reviewed_count).to eq(1)
        expect(record.assessments_pending_grading_count).to eq(0)
        expect(record.assessments_not_submitted_count).to eq(1)
        expect(record.assessments_exempt_count).to eq(0)
      end

      it "still includes the assessment in points_max" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.points_max_materialized).to eq(30)
      end
    end

    context "when participation is absent" do
      let(:assignment1) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
      let(:assignment2) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }

      let(:assessment1) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment1,
                                                     lecture: lecture)
      end

      let(:assessment2) do
        FactoryBot.create(:assessment, :with_points, assessable: assignment2,
                                                     lecture: lecture)
      end

      before do
        FactoryBot.create(:assessment_task, assessment: assessment1, max_points: 10)
        FactoryBot.create(:assessment_task, assessment: assessment2, max_points: 20)

        FactoryBot.create(:assessment_participation, :reviewed,
                          assessment: assessment1, user: user)
        FactoryBot.create(:assessment_participation, :absent,
                          assessment: assessment2, user: user)
      end

      it "does not count absent as pending or not submitted" do
        compute
        record = StudentPerformance::Record.find_by(lecture: lecture, user: user)
        expect(record.assessments_total_count).to eq(2)
        expect(record.assessments_reviewed_count).to eq(1)
        expect(record.assessments_pending_grading_count).to eq(0)
        expect(record.assessments_not_submitted_count).to eq(0)
        expect(record.assessments_exempt_count).to eq(0)
      end
    end
  end

  describe "#compute_and_upsert_all_records!" do
    let(:user2) { FactoryBot.create(:confirmed_user) }
    let(:assignment) { FactoryBot.create(:assignment, :with_lecture, lecture: lecture) }
    let(:assessment) do
      FactoryBot.create(:assessment, :with_points, assessable: assignment, lecture: lecture)
    end

    let!(:task) { FactoryBot.create(:assessment_task, assessment: assessment, max_points: 20) }

    before do
      FactoryBot.create(:lecture_membership, user: user2, lecture: lecture)

      p1 = FactoryBot.create(:assessment_participation, :reviewed,
                             assessment: assessment, user: user)
      FactoryBot.create(:assessment_task_point, task: task,
                                                assessment_participation: p1,
                                                points: 15)

      p2 = FactoryBot.create(:assessment_participation, :reviewed,
                             assessment: assessment, user: user2)
      FactoryBot.create(:assessment_task_point, task: task,
                                                assessment_participation: p2,
                                                points: 10)
    end

    it "creates records for all lecture members" do
      described_class.new(lecture: lecture).compute_and_upsert_all_records!
      expect(StudentPerformance::Record.where(lecture: lecture).count).to eq(2)
    end

    it "computes correct points per user" do
      described_class.new(lecture: lecture).compute_and_upsert_all_records!

      record1 = StudentPerformance::Record.find_by(lecture: lecture, user: user)
      record2 = StudentPerformance::Record.find_by(lecture: lecture, user: user2)

      expect(record1.points_total_materialized).to eq(15)
      expect(record2.points_total_materialized).to eq(10)
    end
  end
end
