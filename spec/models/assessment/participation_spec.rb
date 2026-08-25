require "rails_helper"

RSpec.describe(Assessment::Participation, type: :model) do
  describe "factory" do
    it "creates a valid default participation" do
      participation = FactoryBot.create(:assessment_participation)
      expect(participation).to be_valid
    end

    it "creates a participation with tutorial" do
      participation = FactoryBot.create(:assessment_participation, :with_tutorial)
      expect(participation.tutorial).to be_present
    end

    it "creates a pending participation" do
      participation = FactoryBot.create(:assessment_participation, :pending)
      expect(participation.status).to eq("pending")
      expect(participation.submitted_at).to be_nil
    end

    it "creates a submitted participation" do
      participation = FactoryBot.create(:assessment_participation, :submitted)
      expect(participation.status).to eq("pending")
      expect(participation.submitted_at).to be_present
    end

    it "creates a reviewed participation" do
      participation = FactoryBot.create(:assessment_participation, :reviewed)
      expect(participation.status).to eq("reviewed")
      expect(participation.graded_at).to be_present
    end

    it "creates a participation with numeric grade" do
      participation = FactoryBot.create(:assessment_participation, :with_numeric_grade)
      expect([1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0,
              5.0]).to include(participation.grade_numeric)
    end
  end

  describe "validations" do
    let(:assessment) { FactoryBot.create(:assessment) }

    it "requires user to be unique per assessment" do
      user = FactoryBot.create(:confirmed_user)
      FactoryBot.create(:assessment_participation, assessment: assessment, user: user)

      duplicate = FactoryBot.build(:assessment_participation, assessment: assessment,
                                                              user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    context "grade_numeric validation" do
      let(:gradable_assessment) { FactoryBot.create(:assessment, :gradable) }

      it "accepts valid German grades on gradable assessments" do
        valid_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]
        valid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           assessment: gradable_assessment,
                                           grade_numeric: grade)
          expect(participation).to be_valid
        end
      end

      it "rejects invalid grades" do
        invalid_grades = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.0]
        invalid_grades.each do |grade|
          participation = FactoryBot.build(:assessment_participation,
                                           assessment: gradable_assessment,
                                           grade_numeric: grade)
          expect(participation).not_to be_valid
          expect(participation.errors[:grade_numeric]).to be_present
        end
      end

      it "rejects grade_numeric on non-gradable assessments" do
        participation = FactoryBot.build(:assessment_participation,
                                         assessment: assessment,
                                         grade_numeric: 1.0)
        expect(participation).not_to be_valid
        expect(participation.errors[:grade_numeric]).to be_present
      end

      it "allows nil" do
        participation = FactoryBot.build(:assessment_participation, grade_numeric: nil)
        expect(participation).to be_valid
      end
    end
  end

  describe "the grading lifecycle guard" do
    let(:grader) { FactoryBot.create(:confirmed_user) }

    context "while the assignment can still be submitted to" do
      # The default assignment factory puts the deadline 30 days out.
      let(:participation) { FactoryBot.create(:assessment_participation) }

      it "reports grading as closed" do
        expect(participation.assessment.grading_open?).to be(false)
      end

      it "rejects a points total" do
        participation.points_total = 12

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects a text grade" do
        participation.grade_text = "pass"

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects a grader and a grading timestamp" do
        participation.grader = grader
        participation.graded_at = Time.zone.now

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "rejects leaving the pending status" do
        participation.status = :reviewed

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      # A certificate handed in after the window closed has to take the no-show
      # grade with it; clearing is not grading.
      it "allows an exemption to clear an existing grade" do
        # rubocop:disable Rails/SkipsModelValidations
        participation.update_columns(status: :absent, grade_numeric: 5.0)
        # rubocop:enable Rails/SkipsModelValidations
        participation.reload

        participation.assign_attributes(status: :exempt, grade_numeric: nil,
                                        grader_id: nil, graded_at: nil)

        expect(participation).to be_valid
      end

      it "still rejects an exemption that sets a grade" do
        participation.assign_attributes(status: :exempt, grade_numeric: 1.0)

        expect(participation).not_to be_valid
        expect(participation.errors.of_kind?(:base, :early_grading_not_allowed)).to be(true)
      end

      it "allows changes that are not grading data" do
        participation.submitted_at = Time.zone.now

        expect(participation).to be_valid
      end
    end

    context "once the deadline and the grace period have passed" do
      let(:assessment) { FactoryBot.create(:assessment, :for_expired_assignment) }
      let(:participation) do
        FactoryBot.create(:assessment_participation, assessment: assessment)
      end

      it "reports grading as open" do
        expect(participation.assessment.grading_open?).to be(true)
      end

      it "accepts the write that was rejected before" do
        participation.points_total = 12
        participation.grader = grader
        participation.graded_at = Time.zone.now
        participation.status = :reviewed

        expect(participation).to be_valid
      end
    end

    context "with an assessable that never closes" do
      # Talk does not override grading_open?, so it keeps the default of true.
      let(:assessment) { FactoryBot.create(:assessment, :gradable) }
      let(:participation) do
        FactoryBot.create(:assessment_participation, assessment: assessment)
      end

      it "reports grading as open" do
        expect(participation.assessment.grading_open?).to be(true)
      end

      it "accepts grading data straight away" do
        participation.points_total = 12
        participation.status = :reviewed

        expect(participation).to be_valid
      end
    end
  end

  describe "enums" do
    it "supports all status values" do
      statuses = ["pending", "reviewed", "absent", "exempt"]
      statuses.each do |status|
        participation = FactoryBot.build(:assessment_participation, status: status)
        expect(participation.status).to eq(status)
      end
    end
  end

  context "when assignment is ready to be pointed" do
    let!(:user) { FactoryBot.create(:confirmed_user) }
    let!(:assignment) do
      FactoryBot.create(:valid_assignment, deadline: 1.hour.from_now)
    end
    let!(:assessment) do
      FactoryBot.create(:assessment, assessable: assignment, requires_points: true)
    end
    let!(:task1) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:task2) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:task3) { FactoryBot.create(:assessment_task, assessment: assessment) }
    let!(:participation) do
      FactoryBot.create(:assessment_participation,
                        assessment: assessment, user: user,
                        status: :pending,
                        points_total: nil)
    end

    before do
      Timecop.travel(2.hours.from_now)
    end
    after { Timecop.return }

    context "when some tasks are scored and some are not" do
      before do
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task1,
                          points: 5.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task2,
                          points: nil)
      end
      describe "recompute_points_total!" do
        it "updates points_total to the sum of task points" do
          participation.recompute_points_total!
          expect(participation.points_total).to eq(5)
        end
      end
      describe "update_status_if_all_scored!" do
        it "if current status is pending, still keeps the status as pending" do
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("pending")
        end
        it "if current status is reviewed, changes the status to pending" do
          participation.update!(status: :reviewed)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("pending")
        end
        it "if current status is absent, keeps the status as absent" do
          participation.update!(status: :absent)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("absent")
        end
        it "if current status is exempt, keeps the status as exempt" do
          participation.update!(status: :exempt)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("exempt")
        end
        it "if there are no tasks, keeps the status as pending" do
          assignment_empty =
            FactoryBot.create(:valid_assignment, deadline: 1.hour.from_now)
          assessment_empty =
            FactoryBot.create(:assessment, assessable: assignment_empty, requires_points: true)
          participation_empty =
            FactoryBot.create(:assessment_participation,
                              assessment: assessment_empty, user: user,
                              status: :pending,
                              points_total: nil)
          participation_empty.update_status_if_all_scored!
          expect(participation_empty.status).to eq("pending")
        end
      end
    end

    context "when all tasks are scored" do
      before do
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task1,
                          points: 5.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task2,
                          points: 3.0)
        FactoryBot.create(:assessment_task_point, :with_grader,
                          assessment_participation: participation,
                          task: task3,
                          points: 10.0)
      end
      describe "recompute_points_total!" do
        it "updates points_total to the sum of task points" do
          participation.recompute_points_total!
          expect(participation.points_total).to eq(18)
        end
      end
      describe "update_status_if_all_scored!" do
        it "changes the status to reviewed" do
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("reviewed")
        end
        it "keeps the status as reviewed if already reviewed" do
          participation.update!(status: :reviewed)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("reviewed")
        end
        it "if current status is absent, keeps the status as absent" do
          participation.update!(status: :absent)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("absent")
        end
        it "if current status is exempt, keeps the status as exempt" do
          participation.update!(status: :exempt)
          participation.update_status_if_all_scored!
          expect(participation.status).to eq("exempt")
        end
      end
    end
  end
  describe "achievement recomputation trigger" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    before do
      FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
    end

    context "when grade_text changes on an achievement participation" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "recomputes the performance record synchronously" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)

        service = instance_double(
          StudentPerformance::ComputationService,
          compute_and_upsert_record_for: nil
        )
        expect(StudentPerformance::ComputationService)
          .to receive(:new).with(lecture: lecture).and_return(service)
        expect(service).to receive(:compute_and_upsert_record_for).with(user)

        participation.update!(grade_text: "pass")
      end
    end

    context "when grade_text changes on a non-achievement participation" do
      let(:assignment) do
        FactoryBot.create(:assignment, :expired, :with_lecture, lecture: lecture)
      end
      # The assignment brings its own gradebook while the flag is on; building a
      # second one would only try to unset `requires_submission` past the
      # deadline, which the assessment refuses.
      let(:assessment) { assignment.assessment }
      let!(:participation) do
        FactoryBot.create(:assessment_participation,
                          assessment: assessment, user: user)
      end

      it "does not recompute the performance record" do
        expect(StudentPerformance::ComputationService)
          .not_to receive(:new)

        participation.update!(grade_text: "some value")
      end
    end

    context "when a non-grade_text attribute changes" do
      let(:achievement) do
        FactoryBot.create(:achievement, :boolean, lecture: lecture)
      end

      it "recomputes when status changes" do
        participation = achievement.assessment
                                   .assessment_participations
                                   .find_by(user: user)

        expect_any_instance_of(StudentPerformance::ComputationService)
          .to receive(:compute_and_upsert_record_for).with(user)

        participation.update!(status: :reviewed)
      end
    end
  end

  describe "#display_status" do
    # The enum has four values, the views need five: `pending` covers both
    # "has not handed in" and "waiting to be marked", told apart by submitted_at.
    def display_status_for(**attrs)
      FactoryBot.build(:assessment_participation, **attrs).display_status
    end

    it "is :not_submitted while pending with no submission" do
      expect(display_status_for(status: :pending, submitted_at: nil))
        .to eq(:not_submitted)
    end

    it "is :pending_grading while pending with a submission" do
      expect(display_status_for(status: :pending, submitted_at: 1.day.ago))
        .to eq(:pending_grading)
    end

    it "passes every other status through unchanged" do
      [:reviewed, :absent, :exempt].each do |status|
        expect(display_status_for(status: status)).to eq(status)
      end
    end

    it "ignores submitted_at once the status is no longer pending" do
      expect(display_status_for(status: :reviewed, submitted_at: nil))
        .to eq(:reviewed)
    end
  end

  describe ".tutorial_for" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:tutorial) { FactoryBot.create(:tutorial, lecture: lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    it "returns the tutorial_id for a user enrolled in the lecture" do
      TutorialMembership.create!(user: user, tutorial: tutorial)

      result = described_class.tutorial_for(user, lecture)
      expect(result).to eq(tutorial.id)
    end

    it "returns nil when the user has no tutorial membership" do
      result = described_class.tutorial_for(user, lecture)
      expect(result).to be_nil
    end
  end

  describe "performance record recomputation" do
    let(:participation) { FactoryBot.create(:assessment_participation) }
    let(:service) do
      instance_double(StudentPerformance::ComputationService,
                      compute_and_upsert_record_for: true)
    end

    before do
      allow(StudentPerformance::ComputationService)
        .to receive(:new)
        .with(lecture: participation.assessment.lecture)
        .and_return(service)
    end
  end
end
