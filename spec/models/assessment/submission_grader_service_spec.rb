require "rails_helper"

RSpec.describe(Assessment::SubmissionGraderService, type: :model) do
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:scorer) { FactoryBot.create(:confirmed_user) }

  let(:assessment_active) { FactoryBot.create(:assessment, :with_points) }
  let(:task_active) { FactoryBot.create(:assessment_task, assessment: assessment_active) }
  let(:assignment_active) { assessment_active.assessable }
  let(:points_by_task_id) { { task_active.id => "7" } }

  before do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:roster_maintenance)
  end

  describe ".init_participation" do
    let!(:user) { FactoryBot.create(:confirmed_user) }
    let!(:tutorial) { FactoryBot.create(:tutorial, lecture: lecture) }

    it "creates and persists a new participation when none exists" do
      expect do
        described_class.init_participation(assessment_active, user, tutorial)
      end.to change(Assessment::Participation, :count).by(1)
    end

    it "returns a persisted participation" do
      result = described_class.init_participation(assessment_active, user, tutorial)
      expect(result).to be_persisted
    end

    it "associates the participation with the correct assessment and user" do
      result = described_class.init_participation(assessment_active, user, tutorial)
      expect(result.assessment_id).to eq(assessment_active.id)
      expect(result.user_id).to eq(user.id)
    end

    it "returns the existing participation when one already exists" do
      existing = FactoryBot.create(:assessment_participation,
                                   assessment: assessment_active,
                                   user: user,
                                   tutorial: tutorial)
      result = described_class.init_participation(assessment_active, user, tutorial)
      expect(result.id).to eq(existing.id)
    end

    it "does not create a duplicate when participation already exists" do
      FactoryBot.create(:assessment_participation, assessment: assessment_active, user: user,
                                                   tutorial: tutorial)

      expect do
        described_class.init_participation(assessment_active, user, tutorial)
      end.not_to change(Assessment::Participation, :count)
    end
  end

  describe ".score_tasks_by_participation!" do
    context "when assignment is inactive (before deadline)" do
      before do
        @assignment = FactoryBot.create(:assignment, :with_lecture, deadline: 1.hour.from_now)
        @assessment = FactoryBot.create(:assessment,
                                        requires_points: true,
                                        assessable: @assignment,
                                        lecture: @assignment.lecture)
        @task = FactoryBot.create(:assessment_task, assessment: @assessment)
        @points_by_task_id = { @task.id => "7" }
        @participation = FactoryBot.create(:assessment_participation,
                                           assessment: @assessment,
                                           user: FactoryBot.create(:confirmed_user),
                                           status: :pending)
        Timecop.travel(2.hours.from_now)
      end
      after { Timecop.return }

      context "when participation is nil, should reject the request" do
        subject { described_class.score_tasks_by_participation!(nil, @points_by_task_id, scorer) }

        it "does not call PointEntryService" do
          expect(Assessment::PointEntryService).not_to receive(:enter_points)
          subject
        end

        it "does not create any participations" do
          expect { subject }.not_to change(Assessment::Participation, :count)
        end
      end

      context "when submission and assignment are valid" do
        subject do
          described_class.score_tasks_by_participation!(@participation, @points_by_task_id,
                                                        scorer)
        end
        it "calls PointEntryService.enter_points with the existing participation" do
          expect(Assessment::PointEntryService).to receive(:enter_points).once.with(
            @participation,
            @points_by_task_id,
            scorer,
            nil
          )

          subject
        end

        it "does not create a new participation record" do
          allow(Assessment::PointEntryService).to receive(:enter_points)

          expect do
            subject
          end.not_to change(Assessment::Participation, :count)
        end

        it "passes nil as submission" do
          allow(Assessment::PointEntryService).to receive(:enter_points)

          subject

          expect(Assessment::PointEntryService).to have_received(:enter_points)
            .with(anything, anything, anything, nil)
        end
      end
    end

    context "when assignment is active" do
      let!(:participation) do
        FactoryBot.create(
          :assessment_participation,
          assessment: assessment_active,
          user: FactoryBot.create(:confirmed_user),
          status: :pending
        )
      end
      subject do
        described_class.score_tasks_by_participation!(participation, points_by_task_id, scorer)
      end
      it "raises SubmissionGraderError" do
        expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
      end

      it "does not create any participations" do
        expect do
          subject
        rescue StandardError
          nil
        end.not_to change(Assessment::Participation, :count)
      end
    end
  end

  describe ".score_tasks_by_submission!" do
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:tutorial_active) { FactoryBot.create(:tutorial, lecture: assignment_active.lecture) }
    let(:submission_active) do
      FactoryBot.create(:submission, :with_manuscript,
                        assignment: assignment_active,
                        tutorial: tutorial_active)
    end

    context "when assignment is inactive" do
      before do
        @assignment = FactoryBot.create(:assignment, :with_lecture, deadline: 1.hour.from_now)
        @tutorial = FactoryBot.create(:tutorial, lecture: @assignment.lecture)
        @assessment = FactoryBot.create(:assessment,
                                        requires_points: true,
                                        assessable: @assignment,
                                        lecture: @assignment.lecture)
        @assignment.reload
        @task = FactoryBot.create(:assessment_task, assessment: @assessment)
        @points_by_task_id = { @task.id => "7" }
        @submission = FactoryBot.create(:submission, :with_manuscript,
                                        assignment: @assignment,
                                        tutorial: @tutorial,
                                        users: [user])
        Timecop.travel(2.hours.from_now)
      end
      after { Timecop.return }
      context "when submission is nil" do
        subject { described_class.score_tasks_by_submission!(nil, @points_by_task_id, scorer) }

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not create any participations" do
          expect do
            subject
          rescue StandardError
            nil
          end.not_to change(Assessment::Participation, :count)
        end
      end

      context "when submission has no assignment" do
        before { allow(@submission).to receive(:assignment).and_return(nil) }

        subject do
          described_class.score_tasks_by_submission!(@submission, @points_by_task_id, scorer)
        end

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not create any participations" do
          expect do
            subject
          rescue StandardError
            nil
          end.not_to change(Assessment::Participation, :count)
        end
      end

      context "when assignment has no assessment" do
        before { allow(@assignment).to receive(:assessment).and_return(nil) }

        subject do
          described_class.score_tasks_by_submission!(@submission, @points_by_task_id, scorer)
        end

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not create any participations" do
          expect do
            subject
          rescue StandardError
            nil
          end.not_to change(Assessment::Participation, :count)
        end
      end
      context "when submission and assignment are valid" do
        context "when submission has 1 users" do
          subject do
            described_class.score_tasks_by_submission!(@submission, @points_by_task_id, scorer)
          end
          it "calls PointEntryService.enter_points for each user on the submission" do
            expect(Assessment::PointEntryService).to receive(:enter_points).once.with(
              an_instance_of(Assessment::Participation),
              @points_by_task_id,
              scorer,
              @submission
            )

            subject
          end

          it "passes the submission through to PointEntryService" do
            allow(Assessment::PointEntryService).to receive(:enter_points)

            subject

            expect(Assessment::PointEntryService).to have_received(:enter_points)
              .with(anything, anything, anything, @submission)
          end
        end

        context "when the submission has multiple users (team submission)" do
          let(:user2) { FactoryBot.create(:confirmed_user) }
          let(:user3) { FactoryBot.create(:confirmed_user) }
          let(:submission_multi) do
            FactoryBot.create(:submission, :with_manuscript,
                              assignment: @assignment,
                              tutorial: @tutorial,
                              users: [user3, user2])
          end
          subject do
            described_class.score_tasks_by_submission!(submission_multi, @points_by_task_id,
                                                       scorer)
          end
          it "calls PointEntryService once per team member" do
            expect(Assessment::PointEntryService).to receive(:enter_points).twice

            subject
          end
        end
      end

      context "when assignment is active" do
        subject do
          described_class.score_tasks_by_submission!(submission_active, points_by_task_id, scorer)
        end

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not create any participations" do
          expect do
            subject
          rescue StandardError
            nil
          end.not_to change(Assessment::Participation, :count)
        end
      end
    end
  end
end
