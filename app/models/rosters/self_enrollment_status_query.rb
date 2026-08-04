module Rosters
  # For the lecture search cards: given a page of lectures, tells which the
  # user is already rostered into and which still have a group anyone could
  # self-enroll into. Answered in a fixed, small number of queries regardless
  # of how many lectures or groups the page holds — the search renders many
  # cards and paginates on scroll, so per-card or per-group lookups would N+1.
  class SelfEnrollmentStatusQuery
    SELF_ADD_MODES = [:add_only, :add_and_remove].freeze

    # Per rosterable type: how to scope it to a lecture page and which
    # membership association counts towards capacity.
    ENROLLABLE_SOURCES = [
      { klass: Tutorial, membership: :tutorial_memberships,
        page_scope: ->(ids) { { lecture_id: ids } } },
      { klass: Talk, membership: :speaker_talk_joins,
        page_scope: ->(ids) { { lecture_id: ids } } },
      { klass: Cohort, membership: :cohort_memberships,
        page_scope: ->(ids) { { context_type: "Lecture", context_id: ids } } }
    ].freeze

    def initialize(user, lecture_ids)
      @user = user
      @lecture_ids = lecture_ids.to_a
    end

    def rosterized_lecture_ids
      return Set.new if @lecture_ids.empty?

      Set.new(tutorial_member_lecture_ids)
         .merge(talk_member_lecture_ids)
         .merge(cohort_member_lecture_ids)
    end

    # Lecture IDs with at least one group still open for self-enrollment (mode
    # allows it, not locked, not full).
    #
    # Careful: this does not look at the user's own memberships, so it can call
    # a group open that the user is already in. Only ask it for users you know
    # are in no group of the lecture yet — the search card does, its "registered"
    # branch runs first (_lecture.html.erb). Otherwise use allow_self_add?.
    def enrollable_lecture_ids
      return Set.new if @lecture_ids.empty?

      ENROLLABLE_SOURCES.each_with_object(Set.new) do |source, ids|
        collect_enrollable(source, ids)
      end
    end

    private

      def tutorial_member_lecture_ids
        TutorialMembership.where(lecture_id: @lecture_ids, user_id: @user.id)
                          .distinct.pluck(:lecture_id)
      end

      def talk_member_lecture_ids
        Talk.where(lecture_id: @lecture_ids)
            .joins(:speaker_talk_joins)
            .where(speaker_talk_joins: { speaker_id: @user.id })
            .distinct.pluck(:lecture_id)
      end

      def cohort_member_lecture_ids
        Cohort.where(context_type: "Lecture", context_id: @lecture_ids)
              .joins(:cohort_memberships)
              .where(cohort_memberships: { user_id: @user.id })
              .distinct.pluck(:context_id)
      end

      def collect_enrollable(source, ids)
        candidates = source[:klass]
                     .where(source[:page_scope].call(@lecture_ids))
                     .where(self_materialization_mode: SELF_ADD_MODES)
                     .to_a
        return if candidates.empty?

        counts = member_counts(source, candidates.map(&:id))

        candidates.each do |rosterable|
          # locked? short-circuits on skip_campaigns, which self-materialization
          # always sets, so this issues no query for these candidates.
          next if rosterable.locked?
          next if rosterable_full?(rosterable, counts[rosterable.id])

          ids << rosterable.lecture_id
        end
      end

      # One grouped COUNT per type instead of rosterable.full?'s per-record
      # count. Keep the capacity check in sync with Rosters::Rosterable#full?.
      def member_counts(source, candidate_ids)
        source[:klass].where(id: candidate_ids)
                      .joins(source[:membership])
                      .group(source[:klass].arel_table[:id])
                      .count
      end

      def rosterable_full?(rosterable, member_count)
        rosterable.capacity.present? && (member_count || 0) >= rosterable.capacity
      end
  end
end
