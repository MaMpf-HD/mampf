require "rails_helper"

RSpec.describe(Assessment::ExamGraderService, type: :model) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all, teacher: teacher) }
  let(:exam) { FactoryBot.create(:exam, lecture: lecture) }
  let(:assessment) { exam.reload.assessment }
  let(:grader) { FactoryBot.create(:confirmed_user) }
  let(:user) { FactoryBot.create(:confirmed_user) }

  let(:participation) do
    FactoryBot.create(:assessment_participation,
                      assessment: assessment,
                      user: user,
                      status: :pending)
  end

  before do
    allow(grader).to receive(:can_enter_grades_in?).and_return(true)
    allow(grader).to receive(:can_enter_points_in?).and_return(true)
  end

  describe ".set_grade" do
    subject { described_class.set_grade(participation, "1.7", grader, "well done") }

    context "when participation is nil" do
      it "raises ExamGraderError" do
        expect do
          described_class.set_grade(nil, "1.7", grader)
        end.to raise_error(Assessment::ExamGraderService::ExamGraderError,
                           I18n.t("assessment.errors.no_participation"))
      end

      it "does not call GradeEntryService" do
        expect(Assessment::GradeEntryService).not_to receive(:set_grade)
        begin
          described_class.set_grade(nil, "1.7", grader)
        rescue StandardError
          nil
        end
      end
    end

    context "when the participation's assessable is not an exam" do
      let(:assignment) { FactoryBot.create(:valid_assignment, lecture: lecture) }
      let(:assignment_assessment) { assignment.reload.assessment }
      let(:participation) do
        FactoryBot.create(:assessment_participation,
                          assessment: assignment_assessment,
                          user: user)
      end

      it "raises ExamGraderError" do
        expect { subject }.to raise_error(
          Assessment::ExamGraderService::ExamGraderError,
          I18n.t("assessment.exam_grader.assessment_not_exam")
        )
      end

      it "does not call GradeEntryService" do
        expect(Assessment::GradeEntryService).not_to receive(:set_grade)
        begin
          subject
        rescue StandardError
          nil
        end
      end
    end

    context "when the grader cannot enter grades in the exam's lecture" do
      before { allow(grader).to receive(:can_enter_grades_in?).and_return(false) }

      it "raises ExamGraderError" do
        expect { subject }.to raise_error(Assessment::ExamGraderService::ExamGraderError,
                                          I18n.t("assessment.errors.user_cannot_grade"))
      end

      it "does not call GradeEntryService" do
        expect(Assessment::GradeEntryService).not_to receive(:set_grade)
        begin
          subject
        rescue StandardError
          nil
        end
      end
    end

    context "with valid arguments" do
      it "builds grade info and delegates to GradeEntryService.set_grade" do
        grade_info = { grade_numeric: "1.7" }
        expect(Assessment::GradeEntryService).to receive(:build_grade_info)
          .with(grade_numeric: "1.7").and_return(grade_info)
        expect(Assessment::GradeEntryService).to receive(:set_grade)
          .with(participation, grade_info, grader, "well done")

        subject
      end

      it "does not raise" do
        allow(Assessment::GradeEntryService).to receive(:set_grade)
        expect { subject }.not_to raise_error
      end
    end

    context "when comment is omitted" do
      it "passes nil as the comment" do
        allow(Assessment::GradeEntryService).to receive(:build_grade_info)
          .and_return({ grade_numeric: "1.7" })
        expect(Assessment::GradeEntryService).to receive(:set_grade)
          .with(participation, anything, grader, nil)

        described_class.set_grade(participation, "1.7", grader)
      end
    end
  end

  describe ".score_tasks_by_participation!" do
    let(:points_by_task_id) { { 1 => "5" } }

    subject do
      described_class.score_tasks_by_participation!(participation, points_by_task_id, grader)
    end

    context "when participation is nil" do
      it "raises ExamGraderError" do
        expect do
          described_class.score_tasks_by_participation!(nil, points_by_task_id, grader)
        end.to raise_error(Assessment::ExamGraderService::ExamGraderError,
                           I18n.t("assessment.errors.no_participation"))
      end

      it "does not call PointEntryService" do
        expect(Assessment::PointEntryService).not_to receive(:enter_points)
        begin
          described_class.score_tasks_by_participation!(nil, points_by_task_id, grader)
        rescue StandardError
          nil
        end
      end
    end

    context "when the participation has no exam" do
      before { allow(participation).to receive(:assessment).and_return(nil) }

      it "raises ExamGraderError with the missing-exam message" do
        expect { subject }.to raise_error(
          Assessment::ExamGraderService::ExamGraderError,
          I18n.t("assessment.task_points.participation_id_has_no_exam",
                 participation_id: participation.id)
        )
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

    context "when the exam is not open for grading" do
      before { allow(exam).to receive(:grading_open?).and_return(false) }

      it "raises ExamGraderError" do
        expect { subject }.to raise_error(
          Assessment::ExamGraderService::ExamGraderError,
          I18n.t("assessment.task_points.cannot_score_not_grading_open_exam")
        )
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

    context "when the scorer cannot enter points in the exam's lecture" do
      before do
        allow(exam).to receive(:grading_open?).and_return(true)
        allow(grader).to receive(:can_enter_points_in?).and_return(false)
      end

      it "raises ExamGraderError" do
        expect { subject }.to raise_error(Assessment::ExamGraderService::ExamGraderError,
                                          I18n.t("assessment.errors.user_cannot_grade"))
      end
    end

    context "with valid arguments" do
      before { allow(exam).to receive(:grading_open?).and_return(true) }

      it "calls PointEntryService.enter_points with the participation" do
        expect(Assessment::PointEntryService).to receive(:enter_points).once
                                                                       .with(participation, points_by_task_id, grader, nil)

        subject
      end

      it "does not raise" do
        allow(Assessment::PointEntryService).to receive(:enter_points)
        expect { subject }.not_to raise_error
      end
    end
  end

  describe ".find_participation" do
    it "returns nil when assessment is nil" do
      expect(described_class.find_participation(nil, user)).to be_nil
    end

    it "returns nil when user is nil" do
      expect(described_class.find_participation(assessment, nil)).to be_nil
    end

    it "returns the existing participation for the assessment and user" do
      participation.reload
      expect(described_class.find_participation(assessment, user)).to eq(participation)
    end

    it "returns nil when no participation exists for that user" do
      other_user = FactoryBot.create(:confirmed_user)
      expect(described_class.find_participation(assessment, other_user)).to be_nil
    end
  end

  describe ".create_participation" do
    it "creates a new pending participation" do
      other_user = FactoryBot.create(:confirmed_user)

      expect do
        described_class.create_participation(assessment, other_user)
      end.to change(Assessment::Participation, :count).by(1)
    end

    it "returns a persisted participation with status pending" do
      other_user = FactoryBot.create(:confirmed_user)
      result = described_class.create_participation(assessment, other_user)

      expect(result).to be_persisted
      expect(result).to be_pending
    end

    context "when a participation already exists (race condition)" do
      it "returns the existing participation instead of raising" do
        participation.reload

        result = described_class.create_participation(assessment, user)

        expect(result.id).to eq(participation.id)
      end

      it "does not create a duplicate" do
        participation.reload

        expect do
          described_class.create_participation(assessment, user)
        end.not_to change(Assessment::Participation, :count)
      end
    end
  end

  describe ".init_participations" do
    context "when given an empty list" do
      it "returns an empty hash" do
        expect(described_class.init_participations([])).to eq({})
      end
    end

    context "when pairs contain nil assessment or user" do
      it "skips pairs with a nil assessment" do
        result = described_class.init_participations([[nil, user]])
        expect(result).to eq({})
      end

      it "skips pairs with a nil user" do
        result = described_class.init_participations([[assessment, nil]])
        expect(result).to eq({})
      end
    end

    context "when no participations exist yet" do
      let(:user2) { FactoryBot.create(:confirmed_user) }

      it "creates all missing participations" do
        expect do
          described_class.init_participations([[assessment, user], [assessment, user2]])
        end.to change(Assessment::Participation, :count).by(2)
      end

      it "returns a hash keyed by [assessment_id, user_id]" do
        result = described_class.init_participations([[assessment, user]])
        key = [assessment.id, user.id]

        expect(result[key]).to be_persisted
        expect(result[key].user_id).to eq(user.id)
        expect(result[key].assessment_id).to eq(assessment.id)
      end
    end

    context "when some participations already exist" do
      let(:user2) { FactoryBot.create(:confirmed_user) }

      before { participation.reload }

      it "does not recreate existing participations" do
        expect do
          described_class.init_participations([[assessment, user], [assessment, user2]])
        end.to change(Assessment::Participation, :count).by(1)
      end

      it "includes the existing participation in the result" do
        result = described_class.init_participations([[assessment, user], [assessment, user2]])
        key = [assessment.id, user.id]

        expect(result[key].id).to eq(participation.id)
      end
    end

    context "when all pairs already have participations" do
      before { participation.reload }

      it "does not create any new participations" do
        expect do
          described_class.init_participations([[assessment, user]])
        end.not_to change(Assessment::Participation, :count)
      end
    end

    context "with duplicate pairs in the input" do
      it "does not create more than one participation per pair" do
        other_user = FactoryBot.create(:confirmed_user)
        pairs = [[assessment, other_user], [assessment, other_user]]

        expect do
          described_class.init_participations(pairs)
        end.to change(Assessment::Participation, :count).by(1)
      end
    end
  end
end
