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
    FactoryBot.create(:speaker_talk_join, talk: talk, speaker: speaker)
    allow(grader).to receive(:can_grade_in_scope?).and_return(true)
  end

  describe ".init_participations" do
    let(:other_speaker) { FactoryBot.create(:confirmed_user) }
    let(:other_talk) do
      FactoryBot.create(:talk, lecture: seminar, dates: [1.week.from_now])
    end
    let(:other_assessment) { other_talk.reload.assessment }

    before do
      FactoryBot.create(:speaker_talk_join, talk: other_talk, speaker: other_speaker)
    end

    context "when no participations exist" do
      it "creates a participation for each pair" do
        expect do
          described_class.init_participations(
            [[assessment, speaker], [other_assessment, other_speaker]]
          )
        end.to change(Assessment::Participation, :count).by(2)
      end

      it "returns a hash keyed by [assessment_id, user_id]" do
        result = described_class.init_participations(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )

        expect(result.keys).to contain_exactly(
          [assessment.id, speaker.id],
          [other_assessment.id, other_speaker.id]
        )
      end

      it "associates each created participation with the correct assessment and user" do
        result = described_class.init_participations([[assessment, speaker]])
        participation = result[[assessment.id, speaker.id]]

        expect(participation.assessment_id).to eq(assessment.id)
        expect(participation.user_id).to eq(speaker.id)
      end

      it "only issues a single query to load existing participations" do
        expect(Assessment::Participation).to receive(:where).once.and_call_original

        described_class.init_participations(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )
      end
    end

    context "when some participations already exist" do
      let!(:existing) do
        FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
      end

      it "does not create a duplicate for the existing pair" do
        expect do
          described_class.init_participations(
            [[assessment, speaker], [other_assessment, other_speaker]]
          )
        end.to change(Assessment::Participation, :count).by(1)
      end

      it "returns the existing record for the already-persisted pair" do
        result = described_class.init_participations(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )

        expect(result[[assessment.id, speaker.id]].id).to eq(existing.id)
      end

      it "returns a newly created record for the missing pair" do
        result = described_class.init_participations(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )

        expect(result[[other_assessment.id, other_speaker.id]]).to be_persisted
      end
    end

    context "when all participations already exist" do
      let!(:existing) do
        FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
      end

      it "does not create any new records" do
        expect do
          described_class.init_participations([[assessment, speaker]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "returns the existing records" do
        result = described_class.init_participations([[assessment, speaker]])
        expect(result[[assessment.id, speaker.id]].id).to eq(existing.id)
      end
    end

    context "when the pairs list contains duplicate pairs" do
      it "only creates one participation per unique pair" do
        expect do
          described_class.init_participations(
            [[assessment, speaker], [assessment, speaker]]
          )
        end.to change(Assessment::Participation, :count).by(1)
      end
    end

    context "when a pair has a nil assessment or nil user" do
      it "skips pairs with a nil assessment" do
        expect do
          described_class.init_participations([[nil, speaker]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "skips pairs with a nil user" do
        expect do
          described_class.init_participations([[assessment, nil]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "does not include skipped pairs in the returned hash" do
        result = described_class.init_participations(
          [[nil, speaker], [assessment, nil], [assessment, speaker]]
        )

        expect(result.keys).to contain_exactly([assessment.id, speaker.id])
      end
    end

    context "when given an empty list" do
      it "returns an empty hash" do
        expect(described_class.init_participations([])).to eq({})
      end

      it "does not query the database" do
        expect(Assessment::Participation).not_to receive(:where)
        described_class.init_participations([])
      end
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
