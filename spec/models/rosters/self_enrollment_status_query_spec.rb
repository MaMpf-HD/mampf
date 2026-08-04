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

    it "includes a seminar with a self-enrollment talk" do
      seminar = create(:seminar)
      create(:talk, lecture: seminar, self_materialization_mode: :add_only)

      expect(described_class.new(user, [seminar.id]).enrollable_lecture_ids)
        .to contain_exactly(seminar.id)
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

    it "excludes a seminar whose self-enrollment talk is full" do
      seminar = create(:seminar)
      talk = create(:talk, lecture: seminar, capacity: 1,
                           self_materialization_mode: :add_only)
      create(:speaker_talk_join, talk: talk, speaker: create(:confirmed_user))

      expect(described_class.new(user, [seminar.id]).enrollable_lecture_ids)
        .to be_empty
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

    context "with groups that did not skip campaigns" do
      # Opening a group for self-enrollment usually sets skip_campaigns, but a
      # group that outlived a completed campaign keeps it unset.
      def post_campaign_lecture
        group_lecture = create(:lecture)
        campaign = create(:registration_campaign, :completed,
                          campaignable: group_lecture)
        campaign.registration_items.each do |item|
          item.registerable.update!(self_materialization_mode: :add_only)
        end
        group_lecture
      end

      it "includes a lecture whose group outlived a completed campaign" do
        group_lecture = post_campaign_lecture

        expect(described_class.new(user, [group_lecture.id]).enrollable_lecture_ids)
          .to contain_exactly(group_lecture.id)
      end

      it "excludes a lecture whose group is still awaiting its campaign" do
        campaign = create(:registration_campaign, :open, campaignable: lecture)
        campaign.registration_items.each do |item|
          # the model refuses this combination, which is what we want to prove
          # the query does not rely on
          item.registerable
              .update_column(:self_materialization_mode, 1) # rubocop:disable Rails/SkipsModelValidations
        end

        expect(query.enrollable_lecture_ids).to be_empty
      end

      it "stays bounded instead of asking each group for its campaign" do
        lectures = Array.new(4) { post_campaign_lecture }
        wide_query = described_class.new(user, lectures.map(&:id))

        queries = count_queries { wide_query.enrollable_lecture_ids }

        expect(wide_query.enrollable_lecture_ids).to match_array(lectures.map(&:id))
        # one campaign lookup per type, not one per group
        expect(queries).to be <= 9
      end
    end
  end
end
