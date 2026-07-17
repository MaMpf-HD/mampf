require "rails_helper"

RSpec.describe(Rosters::SelfEnrollmentStatusQuery) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }

  subject(:query) { described_class.new(user, [lecture.id]) }

  describe "#rosterized_lecture_ids" do
    it "includes a lecture where the user is in a tutorial" do
      tutorial = create(:tutorial, lecture: lecture)
      create(:tutorial_membership, tutorial: tutorial, user: user)

      expect(query.rosterized_lecture_ids).to contain_exactly(lecture.id)
    end

    it "includes a lecture where the user is in a cohort" do
      cohort = create(:cohort, context: lecture)
      create(:cohort_membership, cohort: cohort, user: user)

      expect(query.rosterized_lecture_ids).to contain_exactly(lecture.id)
    end

    it "includes a seminar where the user speaks in a talk" do
      seminar = create(:seminar)
      talk = create(:talk, lecture: seminar)
      create(:speaker_talk_join, talk: talk, speaker: user)

      expect(described_class.new(user, [seminar.id]).rosterized_lecture_ids)
        .to contain_exactly(seminar.id)
    end

    it "excludes a lecture where the user is not a member" do
      create(:tutorial, lecture: lecture)

      expect(query.rosterized_lecture_ids).to be_empty
    end
  end

  describe "#enrollable_lecture_ids" do
    it "includes a lecture with a self-enrollment tutorial" do
      create(:tutorial, lecture: lecture, self_materialization_mode: :add_only)

      expect(query.enrollable_lecture_ids).to contain_exactly(lecture.id)
    end

    it "includes a lecture with a self-enrollment cohort" do
      create(:cohort, context: lecture, self_materialization_mode: :add_and_remove)

      expect(query.enrollable_lecture_ids).to contain_exactly(lecture.id)
    end

    it "excludes a lecture whose groups have self-enrollment disabled" do
      create(:tutorial, lecture: lecture, self_materialization_mode: :disabled)

      expect(query.enrollable_lecture_ids).to be_empty
    end

    it "excludes a lecture whose self-enrollment group is full" do
      tutorial = create(:tutorial, lecture: lecture, capacity: 1,
                                   self_materialization_mode: :add_only)
      create(:tutorial_membership, tutorial: tutorial, user: create(:confirmed_user))

      expect(query.enrollable_lecture_ids).to be_empty
    end
  end
end
