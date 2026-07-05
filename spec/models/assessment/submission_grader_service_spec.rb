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

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not call PointEntryService" do
          expect(Assessment::PointEntryService).not_to receive(:enter_points)
          begin
            subject
          rescue StandardError
            nil
          end
        end

        it "does not create any participations" do
          expect do
            subject
          rescue StandardError
            nil
          end.not_to change(Assessment::Participation, :count)
        end
      end

      context "when participation has no resolvable assignment" do
        before { allow(@participation).to receive(:assessment).and_return(nil) }

        subject do
          described_class.score_tasks_by_participation!(@participation, @points_by_task_id, scorer)
        end

        it "raises SubmissionGraderError" do
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end

        it "does not call PointEntryService" do
          expect(Assessment::PointEntryService).not_to receive(:enter_points)
          begin
            subject
          rescue StandardError
            nil
          end
        end
      end

      context "when participation and assignment are valid" do
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

      context "when submission and assignment are valid" do
        context "when submission has 1 user" do
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
    end

    context "when assignment is active" do
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

  describe ".score_tasks_by_types!" do
    let(:user) { FactoryBot.create(:confirmed_user) }

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
      @participation = FactoryBot.create(:assessment_participation,
                                         assessment: @assessment,
                                         user: user,
                                         tutorial: @tutorial)
      @submission.reload
      @participation.reload
      @assessment.reload
      allow(scorer).to receive(:can_grade_in_scope?).and_return(true)
      Timecop.travel(2.hours.from_now)
    end
    after { Timecop.return }

    let(:validated_tutorials_ids) { [] }

    context "when target is submission" do
      subject do
        described_class.score_tasks_by_types!(
          { "target" => "submission", "id" => @submission.id, "task_points" => @points_by_task_id },
          scorer,
          validated_tutorials_ids
        )
      end

      it "delegates to score_tasks_by_submission!" do
        expect(described_class).to receive(:score_tasks_by_submission!).once.with(
          @submission,
          @points_by_task_id,
          scorer
        )
        subject
      end

      it "raises ActiveRecord::RecordNotFound when the submission id does not exist" do
        entry = { "target" => "submission", "id" => 999_999, "task_points" => @points_by_task_id }
        expect do
          described_class.score_tasks_by_types!(entry, scorer, validated_tutorials_ids)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises SubmissionGraderError when the scorer cannot grade the submission's tutorial" do
        allow(scorer).to receive(:can_grade_in_scope?).and_return(false)

        expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
      end

      it "adds the tutorial id to validated_tutorials_ids on success" do
        allow(Assessment::PointEntryService).to receive(:enter_points)

        subject

        expect(validated_tutorials_ids).to include(@tutorial.id)
      end

      it "does not re-validate a tutorial already in validated_tutorials_ids" do
        allow(Assessment::PointEntryService).to receive(:enter_points)
        validated_tutorials_ids << @tutorial.id
        expect(Tutorial).not_to receive(:find)
        subject
      end
    end

    context "when target is participation" do
      subject do
        described_class.score_tasks_by_types!(
          { "target" => "participation", "id" => @participation.id,
            "task_points" => @points_by_task_id },
          scorer,
          validated_tutorials_ids
        )
      end

      it "delegates to score_tasks_by_participation!" do
        expect(described_class).to receive(:score_tasks_by_participation!).once.with(
          @participation,
          @points_by_task_id,
          scorer
        )
        subject
      end

      it "raises ActiveRecord::RecordNotFound when the participation id does not exist" do
        entry = { "target" => "participation", "id" => 999_999,
                  "task_points" => @points_by_task_id }
        expect do
          described_class.score_tasks_by_types!(entry, scorer, validated_tutorials_ids)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises SubmissionGraderError when the scorer cannot grade the participation's tutorial" do
        allow(scorer).to receive(:can_grade_in_scope?).and_return(false)

        expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
      end

      it "adds the tutorial id to validated_tutorials_ids on success" do
        subject
        expect(validated_tutorials_ids).to include(@tutorial.id)
      end

      context "when participation has no tutorial_id (falls back to lecture)" do
        let!(:participation_no_tutorial) do
          FactoryBot.create(:assessment_participation, assessment: @assessment, user:
            FactoryBot.create(:confirmed_user), tutorial: nil)
        end

        subject do
          described_class.score_tasks_by_types!(
            { "target" => "participation", "id" => participation_no_tutorial.id,
              "task_points" => @points_by_task_id },
            scorer,
            validated_tutorials_ids
          )
        end

        it "raises SubmissionGraderError when the scorer cannot grade the lecture" do
          allow(scorer).to receive(:can_grade_in_scope?).and_return(false)
          expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
        end
      end
    end

    context "when target is unknown" do
      subject do
        described_class.score_tasks_by_types!(
          { "target" => "unknown", "id" => @submission.id, "task_points" => @points_by_task_id },
          scorer,
          validated_tutorials_ids
        )
      end

      it "raises SubmissionGraderError" do
        expect { subject }.to raise_error(Assessment::SubmissionGraderService::SubmissionGraderError)
      end

      it "does not call score_tasks_by_submission!" do
        expect(described_class).not_to receive(:score_tasks_by_submission!)
        begin
          subject
        rescue StandardError
          nil
        end
      end

      it "does not call score_tasks_by_participation!" do
        expect(described_class).not_to receive(:score_tasks_by_participation!)
        begin
          subject
        rescue StandardError
          nil
        end
      end
    end
  end

  describe ".score_multi_teams_by_types!" do
    let(:user) { FactoryBot.create(:confirmed_user) }

    before do
      @assignment = FactoryBot.create(:assignment, :with_lecture, deadline: 1.hour.from_now)
      @tutorial = FactoryBot.create(:tutorial, lecture: @assignment.lecture)
      @assessment = FactoryBot.create(:assessment,
                                      requires_points: true,
                                      assessable: @assignment,
                                      lecture: @assignment.lecture)
      @task = FactoryBot.create(:assessment_task, assessment: @assessment)
      @submission = FactoryBot.create(:submission, :with_manuscript,
                                      assignment: @assignment,
                                      tutorial: @tutorial,
                                      users: [user])
      allow(scorer).to receive(:can_grade_in_scope?).and_return(true)
      Timecop.travel(2.hours.from_now)
    end
    after { Timecop.return }

    let(:records) do
      [{ "target" => "submission", "id" => @submission.id,
         "task_points" => { @task.id => "7" } }]
    end

    it "wraps processing in a transaction and calls score_tasks_by_types! for each record" do
      expect(described_class).to receive(:score_tasks_by_types!).once
      described_class.score_multi_teams_by_types!(records, scorer)
    end

    it "rolls back all changes if one record raises" do
      bad_records = records + [{ "target" => "submission", "id" => 999_999, "task_points" => {} }]

      expect do
        described_class.score_multi_teams_by_types!(bad_records, scorer)
      rescue StandardError
        nil
      end.not_to change(Assessment::Participation, :count)
    end
  end
end
