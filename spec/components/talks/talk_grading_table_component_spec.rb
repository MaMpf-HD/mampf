require "rails_helper"

RSpec.describe(TalkGradingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:seminar) { create(:lecture, :is_seminar, teacher: teacher) }

  let(:component) { described_class.new(seminar: seminar) }

  describe "#gradable_talks" do
    let(:speaker) { create(:confirmed_user) }

    context "when a talk has speakers and an assessment" do
      let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

      before do
        create(:speaker_talk_join, talk: talk, speaker: speaker)
        talk.reload
      end

      it "includes the talk" do
        expect(component.gradable_talks).to include(talk)
      end
    end

    context "when a talk has no speakers" do
      let!(:talk_without_speakers) do
        create(:talk, lecture: seminar, dates: [1.week.from_now])
      end

      before { create(:assessment, assessable: talk_without_speakers, lecture: seminar) }

      it "excludes the talk" do
        expect(component.gradable_talks).not_to include(talk_without_speakers)
      end
    end

    context "when a talk has speakers but no assessment" do
      let!(:talk_without_assessment) do
        create(:talk, :without_assessment, lecture: seminar, dates: [1.week.from_now])
      end

      before { create(:speaker_talk_join, talk: talk_without_assessment, speaker: speaker) }

      it "excludes the talk" do
        expect(component.gradable_talks).not_to include(talk_without_assessment)
      end
    end
  end

  describe "#legacy_talks" do
    let(:speaker) { create(:confirmed_user) }

    context "when a talk has speakers but no assessment" do
      let!(:talk_without_assessment) do
        create(:talk, :without_assessment, lecture: seminar, dates: [1.week.from_now])
      end

      before { create(:speaker_talk_join, talk: talk_without_assessment, speaker: speaker) }

      it "includes the talk" do
        expect(component.legacy_talks).to include(talk_without_assessment)
      end
    end

    context "when a talk has speakers and an assessment" do
      let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

      before do
        create(:speaker_talk_join, talk: talk, speaker: speaker)
        create(:assessment, assessable: talk, lecture: seminar)
        talk.reload
      end

      it "excludes the talk" do
        expect(component.legacy_talks).not_to include(talk)
      end
    end

    context "when a talk has no speakers" do
      let!(:talk_without_speakers) do
        create(:talk, lecture: seminar, dates: [1.week.from_now])
      end

      it "excludes the talk" do
        expect(component.legacy_talks).not_to include(talk_without_speakers)
      end
    end
  end

  describe "#rows" do
    let(:first_speaker) { create(:confirmed_user) }
    let(:second_speaker) { create(:confirmed_user) }
    let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }
    let!(:later_talk) { create(:talk, lecture: seminar, dates: [2.weeks.from_now]) }

    before do
      create(:speaker_talk_join, talk: talk, speaker: first_speaker)
      create(:speaker_talk_join, talk: talk, speaker: second_speaker)
      create(:speaker_talk_join, talk: later_talk, speaker: first_speaker)
      seminar.reload
    end

    it "has one row per speaker, talk by talk" do
      expect(component.rows.map { |row| [row.assessment.assessable, row.user] })
        .to eq([[talk, first_speaker], [talk, second_speaker], [later_talk, first_speaker]])
    end

    it "counts the rows' states for the summary" do
      expect(component.row_statuses).to eq([:pending_grading] * 3)
    end
  end

  describe "#status_options" do
    it "offers the states a talk's row can show, by their labels" do
      expect(component.status_options.map(&:first)).to eq(["reviewed", "pending_grading"])
    end
  end

  describe "#initialize" do
    it "sets @seminar" do
      expect(component.instance_variable_get(:@seminar)).to eq(seminar)
    end

    it "preloads talks with speakers and assessment" do
      expect(component.instance_variable_get(:@talks)).to eq(seminar.talks)
    end
  end

  describe "rendering" do
    it "renders without error" do
      expect { render_inline(component) }.not_to raise_error
    end
  end
end
