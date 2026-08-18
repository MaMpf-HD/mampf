require "rails_helper"

RSpec.describe(Assessment::TalkGraderService, type: :model) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:seminar) do
    FactoryBot.create(:lecture, :released_for_all, sort: "seminar", teacher: teacher)
  end
  let(:talk) { FactoryBot.create(:talk, lecture: seminar, dates: [1.week.from_now]) }
  let(:speaker) { FactoryBot.create(:confirmed_user) }
  let(:assessment) { talk.reload.assessment }
  let(:grader) { FactoryBot.create(:confirmed_user) }

  before do
    Flipper.enable(:assessment_grading)
    FactoryBot.create(:speaker_talk_join, talk: talk, speaker: speaker)
    allow(grader).to receive(:can_grade_in_scope?).and_return(true)
  end

  after do
    Flipper.disable(:assessment_grading)
  end

  describe ".init_participation" do
    it "creates and persists a new participation when none exists" do
      expect do
        result = described_class.init_participation(assessment, speaker, talk)
        result.save!
      end.to change(Assessment::Participation, :count).by(1)
    end

    it "returns an initialized (not yet persisted) participation when none exists" do
      result = described_class.init_participation(assessment, speaker, talk)
      expect(result).not_to be_persisted
    end

    it "associates the participation with the correct assessment and user" do
      result = described_class.init_participation(assessment, speaker, talk)
      expect(result.assessment_id).to eq(assessment.id)
      expect(result.user_id).to eq(speaker.id)
    end

    it "returns the existing participation when one already exists" do
      existing = FactoryBot.create(:assessment_participation,
                                   assessment: assessment,
                                   user: speaker)
      result = described_class.init_participation(assessment, speaker, talk)
      expect(result.id).to eq(existing.id)
    end

    it "does not create a duplicate when participation already exists" do
      FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)

      expect do
        described_class.init_participation(assessment, speaker, talk)
      end.not_to change(Assessment::Participation, :count)
    end

    it "raises TalkGraderError when assessment is nil" do
      expect do
        described_class.init_participation(nil, speaker, talk)
      end.to raise_error(Assessment::TalkGraderService::TalkGraderError)
    end

    it "raises TalkGraderError when user is nil" do
      expect do
        described_class.init_participation(assessment, nil, talk)
      end.to raise_error(Assessment::TalkGraderService::TalkGraderError)
    end

    it "raises TalkGraderError when talk is nil" do
      expect do
        described_class.init_participation(assessment, speaker, nil)
      end.to raise_error(Assessment::TalkGraderService::TalkGraderError)
    end
  end

  describe ".set_grade" do
    let(:participation) do
      FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
    end

    context "when participation is nil" do
      subject { described_class.set_grade(nil, "1.0", grader) }

      it "raises TalkGraderError" do
        expect { subject }.to raise_error(Assessment::TalkGraderService::TalkGraderError)
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

    context "when participation's assessment is not attached to a talk" do
      let(:assignment) { FactoryBot.create(:assignment, :with_lecture) }
      let(:assignment_assessment) do
        FactoryBot.create(:assessment, assessable: assignment, lecture: assignment.lecture)
      end
      let(:assignment_participation) do
        FactoryBot.create(:assessment_participation,
                          assessment: assignment_assessment,
                          user: speaker)
      end

      subject { described_class.set_grade(assignment_participation, "1.0", grader) }

      it "raises TalkGraderError" do
        expect { subject }.to raise_error(Assessment::TalkGraderService::TalkGraderError)
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

    context "when grader cannot grade in the talk's lecture scope" do
      before { allow(grader).to receive(:can_grade_in_scope?).and_return(false) }

      subject { described_class.set_grade(participation, "1.0", grader) }

      it "raises TalkGraderError" do
        expect { subject }.to raise_error(Assessment::TalkGraderService::TalkGraderError)
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

    context "when participation and talk are valid" do
      subject { described_class.set_grade(participation, "1.0", grader, "well done") }

      it "builds grade_info via GradeEntryService.build_grade_info with grade_numeric" do
        expect(Assessment::GradeEntryService).to receive(:build_grade_info)
          .with(grade_numeric: "1.0")
          .and_call_original

        allow(Assessment::GradeEntryService).to receive(:set_grade)

        subject
      end

      it "calls GradeEntryService.set_grade with info" do
        grade_info = Assessment::GradeEntryService.build_grade_info(grade_numeric: "1.0")
        allow(Assessment::GradeEntryService).to receive(:build_grade_info).and_return(grade_info)

        expect(Assessment::GradeEntryService).to receive(:set_grade).once.with(
          participation,
          grade_info,
          grader,
          "well done"
        )

        subject
      end

      it "does not raise" do
        allow(Assessment::GradeEntryService).to receive(:set_grade)
        expect { subject }.not_to raise_error
      end
    end

    context "when comment is not provided" do
      subject { described_class.set_grade(participation, "1.0", grader) }

      it "calls GradeEntryService.set_grade with nil comment" do
        expect(Assessment::GradeEntryService).to receive(:set_grade).once.with(
          participation,
          anything,
          grader,
          nil
        )

        subject
      end
    end
  end
end
