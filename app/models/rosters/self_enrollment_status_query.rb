module Rosters
  # For the lecture search cards: given a page of lectures, tells which the
  # user is already rostered into and which still have a group anyone could
  # self-enroll into. Bounded queries, since the search page renders many cards
  # and per-card lookups would be N+1.
  class SelfEnrollmentStatusQuery
    SELF_ADD_MODES = [:add_only, :add_and_remove].freeze

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

    # Lectures with a group that still accepts self-enrollment (mode allows it,
    # not locked, not full). Deliberately user-independent: the card consults
    # this only for users who are not already rostered, so allow_self_add?'s
    # "not already a member" clause is covered by that ordering.
    def enrollable_lecture_ids
      return Set.new if @lecture_ids.empty?

      candidates.each_with_object(Set.new) do |rosterable, ids|
        ids << lecture_id_for(rosterable) unless rosterable.locked? || rosterable.full?
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

      def candidates
        [
          Tutorial.where(lecture_id: @lecture_ids,
                         self_materialization_mode: SELF_ADD_MODES),
          Talk.where(lecture_id: @lecture_ids,
                     self_materialization_mode: SELF_ADD_MODES),
          Cohort.where(context_type: "Lecture", context_id: @lecture_ids,
                       self_materialization_mode: SELF_ADD_MODES)
        ].flat_map(&:to_a)
      end

      def lecture_id_for(rosterable)
        rosterable.is_a?(Cohort) ? rosterable.context_id : rosterable.lecture_id
      end
  end
end
