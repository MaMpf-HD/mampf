module Rosters
  # For the lecture search cards: given a page of lectures, tells which the
  # user is already rostered into and which still have a group anyone could
  # self-enroll into. Answered in a fixed, small number of queries regardless
  # of how many lectures or groups the page holds — the search renders many
  # cards and paginates on scroll, so per-card or per-group lookups would N+1.
  class SelfEnrollmentStatusQuery
    # The group types a lecture can be joined through. Listing them in Rosterable
    # would autoload these models while they are including it; its TYPE_CLASS_MAP
    # wraps its classes in lambdas for the same reason.
    ENROLLABLE_TYPES = [Tutorial, Talk, Cohort].freeze

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

      ENROLLABLE_TYPES.each_with_object(Set.new) do |klass, ids|
        collect_enrollable(klass, ids)
      end
    end

    private

      def tutorial_member_lecture_ids
        TutorialMembership.where(lecture_id: @lecture_ids, user_id: @user.id)
                          .distinct.pluck(:lecture_id)
      end

      def talk_member_lecture_ids
        Talk.for_lectures(@lecture_ids)
            .joins(:speaker_talk_joins)
            .where(speaker_talk_joins: { speaker_id: @user.id })
            .distinct.pluck(:lecture_id)
      end

      def cohort_member_lecture_ids
        Cohort.for_lectures(@lecture_ids)
              .joins(:cohort_memberships)
              .where(cohort_memberships: { user_id: @user.id })
              .distinct.pluck(:context_id)
      end

      def collect_enrollable(klass, ids)
        candidates = klass.for_lectures(@lecture_ids).self_addable.to_a
        return if candidates.empty?

        counts = member_counts(klass, candidates)
        locked = locked_ids(klass, candidates)

        candidates.each do |rosterable|
          next if locked.include?(rosterable.id)
          next if rosterable.full_for_count?(counts[rosterable.id] || 0)

          ids << rosterable.lecture_id
        end
      end

      # locked? asks per record whether a completed campaign exists. Enabling
      # self-enrollment normally sets skip_campaigns, and those are never
      # locked — but a group that outlived a campaign can keep it unset, so
      # answer for the whole batch instead of trusting that.
      def locked_ids(klass, candidates)
        managed = candidates.select(&:campaign_managed?)
        return Set.new if managed.empty?

        completed = Registration::Campaign
                    .joins(:registration_items)
                    .where(status: :completed,
                           registration_items: {
                             registerable_type: klass.name,
                             registerable_id: managed.map(&:id)
                           })
                    .pluck("registration_items.registerable_id")

        managed.to_set(&:id) - completed
      end

      # One grouped COUNT per type instead of rosterable.full?'s per-record
      # count. Rosterables with an empty roster are absent from the result.
      def member_counts(klass, candidates)
        klass.where(id: candidates.map(&:id))
             .joins(klass.roster_association_name)
             .group(klass.arel_table[:id])
             .count
      end
  end
end
