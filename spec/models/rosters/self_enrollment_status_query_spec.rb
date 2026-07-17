require "rails_helper"

RSpec.describe(Rosters::SelfEnrollmentStatusQuery) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }

  subject(:query) { described_class.new(user, [lecture.id]) }

  def count_queries
    count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION|CACHE/)
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription)
  end

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

    it "issues a bounded number of queries regardless of candidate count" do
      lectures = create_list(:lecture, 8)
      lectures.each do |group_lecture|
        create(:tutorial, lecture: group_lecture, capacity: 5,
                          self_materialization_mode: :add_only)
      end
      wide_query = described_class.new(user, lectures.map(&:id))

      queries = count_queries { wide_query.enrollable_lecture_ids }

      expect(wide_query.enrollable_lecture_ids).to match_array(lectures.map(&:id))
      # a per-candidate full?/locked? lookup would scale with the 8 groups; the
      # batched counts keep it flat (candidate load + grouped count per type)
      expect(queries).to be <= 6
    end
  end
end
