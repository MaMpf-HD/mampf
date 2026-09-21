require "rails_helper"

RSpec.describe(Assessment::ParticipationIndex, type: :model) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:seminar) do
    FactoryBot.create(:lecture, :released_for_all, sort: "seminar", teacher: teacher)
  end
  let(:talk) { FactoryBot.create(:talk, lecture: seminar, dates: [1.week.from_now]) }
  let(:speaker) { FactoryBot.create(:confirmed_user) }
  let(:assessment) { talk.reload.assessment }

  before { FactoryBot.create(:speaker_talk_join, talk: talk, speaker: speaker) }

  describe ".create_participation" do
    # Two tabs open the seminar at once: the second one's insert is refused by
    # the model's uniqueness validation before the index ever sees it.
    it "hands back the row another request created first" do
      existing = FactoryBot.create(:assessment_participation, assessment: assessment,
                                                              user: speaker)

      expect(described_class.create_participation(assessment, speaker)).to eq(existing)
    end

    it "lets any other refusal through" do
      allow(Assessment::Participation).to receive(:create!) do
        record = Assessment::Participation.new
        record.errors.add(:status, :invalid)
        raise(ActiveRecord::RecordInvalid, record)
      end

      expect { described_class.create_participation(assessment, speaker) }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe ".rows_for" do
    let(:lecture) { FactoryBot.create(:lecture, :released_for_all, teacher: teacher) }
    let(:group) { FactoryBot.create(:tutorial, lecture: lecture) }
    let(:achievement) { FactoryBot.create(:achievement, :boolean, lecture: lecture) }
    let(:members) { FactoryBot.create_list(:confirmed_user, 3) }

    it "seeds the missing rows in one statement, in the groups given, and loads them all" do
      existing = FactoryBot.create(:assessment_participation, assessment: achievement.assessment,
                                                              user: members.first, tutorial: group)
      groups = members.to_h { |member| [member.id, group] }
      inserts = 0
      callback = lambda { |*, payload|
        inserts += 1 if payload[:sql].start_with?("INSERT INTO \"assessment_participations\"")
      }

      rows = ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        described_class.rows_for(achievement.assessment, members, groups)
      end

      expect(inserts).to eq(1)
      expect(rows.keys).to match_array(members.map(&:id))
      expect(rows[members.first.id]).to eq(existing)
      expect(rows.values.map(&:tutorial).uniq).to eq([group])
    end

    it "hands a blank row to the group its person is in now, and leaves one with a value" do
      moved = FactoryBot.create(:assessment_participation, assessment: achievement.assessment,
                                                           user: members.first, tutorial: group)
      kept = FactoryBot.create(:assessment_participation, assessment: achievement.assessment,
                                                          user: members.second, tutorial: group,
                                                          grade_text: "pass")
      elsewhere = FactoryBot.create(:tutorial, lecture: lecture)
      groups = { members.first.id => elsewhere, members.second.id => elsewhere }

      described_class.rows_for(achievement.assessment, members.first(2), groups)

      expect(moved.reload.tutorial).to eq(elsewhere)
      expect(kept.reload.tutorial).to eq(group)
    end

    # A rejected upload leaves the row looking blank; the file is still in
    # the group's stack, and so is the row - the table and the single-row
    # question agree.
    it "leaves a row behind an uploaded hand-in with the upload's group" do
      sheet = FactoryBot.create(:assignment, lecture: lecture)
      FactoryBot.create(:assessment, :with_points, assessable: sheet)
      elsewhere = FactoryBot.create(:tutorial, lecture: lecture)
      FactoryBot.create(:submission, :with_manuscript, assignment: sheet, tutorial: group,
                                                       users: [members.first], accepted: false)
      row = FactoryBot.create(:assessment_participation, assessment: sheet.reload.assessment,
                                                         user: members.first, tutorial: group)

      described_class.rehome_blank_rows({ members.first.id => row },
                                        { members.first.id => elsewhere })

      expect(row.reload.tutorial).to eq(group)
      expect(described_class.group_holding(row)).to eq(group)
    end
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
          described_class.build(
            [[assessment, speaker], [other_assessment, other_speaker]]
          )
        end.to change(Assessment::Participation, :count).by(2)
      end

      it "returns a hash keyed by [assessment_id, user_id]" do
        result = described_class.build(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )

        expect(result.keys).to contain_exactly(
          [assessment.id, speaker.id],
          [other_assessment.id, other_speaker.id]
        )
      end

      it "associates each created participation with the correct assessment and user" do
        result = described_class.build([[assessment, speaker]])
        participation = result[[assessment.id, speaker.id]]

        expect(participation.assessment_id).to eq(assessment.id)
        expect(participation.user_id).to eq(speaker.id)
      end
    end

    context "when some participations already exist" do
      let!(:existing) do
        FactoryBot.create(:assessment_participation, assessment: assessment, user: speaker)
      end

      it "does not create a duplicate for the existing pair" do
        expect do
          described_class.build(
            [[assessment, speaker], [other_assessment, other_speaker]]
          )
        end.to change(Assessment::Participation, :count).by(1)
      end

      it "returns the existing record for the already-persisted pair" do
        result = described_class.build(
          [[assessment, speaker], [other_assessment, other_speaker]]
        )

        expect(result[[assessment.id, speaker.id]].id).to eq(existing.id)
      end

      it "returns a newly created record for the missing pair" do
        result = described_class.build(
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
          described_class.build([[assessment, speaker]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "returns the existing records" do
        result = described_class.build([[assessment, speaker]])
        expect(result[[assessment.id, speaker.id]].id).to eq(existing.id)
      end
    end

    context "when the pairs list contains duplicate pairs" do
      it "only creates one participation per unique pair" do
        expect do
          described_class.build(
            [[assessment, speaker], [assessment, speaker]]
          )
        end.to change(Assessment::Participation, :count).by(1)
      end
    end

    context "when a pair has a nil assessment or nil user" do
      it "skips pairs with a nil assessment" do
        expect do
          described_class.build([[nil, speaker]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "skips pairs with a nil user" do
        expect do
          described_class.build([[assessment, nil]])
        end.not_to change(Assessment::Participation, :count)
      end

      it "does not include skipped pairs in the returned hash" do
        result = described_class.build(
          [[nil, speaker], [assessment, nil], [assessment, speaker]]
        )

        expect(result.keys).to contain_exactly([assessment.id, speaker.id])
      end
    end

    context "when given an empty list" do
      it "returns an empty hash" do
        expect(described_class.build([])).to eq({})
      end

      it "does not query the database" do
        expect(Assessment::Participation).not_to receive(:where)
        described_class.build([])
      end
    end
  end
end
