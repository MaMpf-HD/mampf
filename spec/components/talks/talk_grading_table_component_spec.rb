require "rails_helper"

RSpec.describe(TalkGradingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:seminar) { create(:lecture, :is_seminar, teacher: teacher) }

  let(:component) { described_class.new(seminar: seminar) }

  describe "#grading_enabled?" do
    it "always returns true" do
      expect(component.grading_enabled?).to eq(true)
    end
  end

  describe "#gradable_talks" do
    let(:speaker) { create(:confirmed_user) }

    context "when a talk has speakers and an assessment" do
      let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

      before do
        create(:speaker_talk_join, talk: talk, speaker: speaker)
        create(:assessment, assessable: talk, lecture: seminar)
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

  describe "#possible_statuses" do
    it "returns pending and reviewed" do
      expect(component.possible_statuses).to eq(["pending", "reviewed"])
    end
  end

  describe "#init_participation" do
    let(:speaker) { create(:confirmed_user) }
    let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }
    let(:assessment) { talk.reload.assessment }

    before do
      create(:speaker_talk_join, talk: talk, speaker: speaker)
      create(:assessment, assessable: talk, lecture: seminar)
      talk.reload
    end

    it "delegates to Assessment::TalkGraderService" do
      expect(Assessment::TalkGraderService).to receive(:init_participation)
        .with(assessment, speaker)
      component.init_participation(assessment, speaker)
    end
  end

  describe "#grade_form_url" do
    let(:speaker) { create(:confirmed_user) }
    let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

    before { render_inline(component) }

    it "returns the grade_talk_user path for the talk and user" do
      expect(component.grade_form_url(talk, speaker))
        .to eq(component.helpers.grade_talk_user_path(talk, speaker))
    end
  end

  describe "#refresh_form_url" do
    let(:speaker) { create(:confirmed_user) }
    let!(:talk) { create(:talk, lecture: seminar, dates: [1.week.from_now]) }

    before { render_inline(component) }

    it "returns the refresh_grade_talk_user path for the talk and user" do
      expect(component.refresh_form_url(talk, speaker))
        .to eq(component.helpers.refresh_grade_talk_user_path(talk, speaker))
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
