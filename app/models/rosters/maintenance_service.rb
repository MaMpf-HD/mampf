module Rosters
  class MaintenanceService
    # Manages manual roster operations (add, remove, move) while enforcing capacity
    # constraints and ensuring transactional integrity
    class CapacityExceededError < StandardError; end
    class GradingDataPresentError < StandardError; end
    class LectureGradingDataPresentError < GradingDataPresentError; end
    class MoveLeavesLectureError < StandardError; end

    # Raised to unwind the move. ActiveRecord::Rollback cannot do that job here:
    # the nested with_lock transactions swallow it and commit anyway.
    class MoveWithoutEffectError < StandardError; end

    def add_user!(user, rosterable, ignore_capacity: false, override_rejection_in: nil)
      added = rosterable.with_lock do
        rosterable.lecture&.lock! if rosterable.enrolls_in_lecture?
        add_user_without_lock!(user,
                               rosterable,
                               ignore_capacity: ignore_capacity,
                               override_rejection_in: override_rejection_in)
      end
      RosterNotificationMailer.added(user, rosterable) if added
      added
    end

    # A caller that removes the user within a larger transaction passes
    # notify: false, since the mail job is enqueued even if that transaction
    # rolls back.
    #
    # Removal from the lecture takes everything there: groups, lists, running
    # registrations and the bookmark. The staff may keep some of the lists,
    # given as keep_list_ids; the bookmark then stays too. Removal from the
    # last group that enrolls the user takes the enrollment along, and the
    # bookmark unless the user is still in a cohort without enrollment there
    # or leaves on their own (by is the user); lists and registrations stay.
    # Returns the roster the user was taken off (the lecture, when the
    # enrollment ended), or nil.
    #
    # Locks the group, then the lecture; removal from the lecture locks the
    # campaigns first, as finalization does, since it withdraws registrations.
    def remove_user!(user, rosterable, notify: true, by: nil, keep_list_ids: [])
      lecture = rosterable.lecture if rosterable.is_a?(Lecture) || rosterable.enrolls_in_lecture?
      places = UserPlaces.new(user)
      left = ActiveRecord::Base.transaction do
        places.lock_campaigns!([lecture]) if rosterable.is_a?(Lecture)
        rosterable.lock!
        lecture&.lock!
        leaving = lecture.present? && leaves_lecture?(user, rosterable, lecture)
        also_leaves_lecture = leaving && lecture != rosterable
        ensure_no_grading_data!(user, rosterable)
        next unless remove_user_without_lock!(user, rosterable, by: by,
                                                                keep_list_ids: keep_list_ids)
        next rosterable unless leaving

        if also_leaves_lecture
          lecture.remove_user_from_roster!(user, by: by)
          user.unbookmark_lecture!(lecture) unless by == user || on_a_list?(user, lecture)
        else
          places.withdraw_registrations!([lecture])
        end
        lecture
      end
      if left && notify
        RosterNotificationMailer.removed(user, rosterable, left_lecture: left != rosterable,
                                                           by_self: by == user)
      end
      left
    end

    # A move from the lecture to a group never takes the person out of the
    # lecture. It moves them out of the group that conflicts with the target,
    # or only adds them to the target if there is none.
    def move_user!(user, from_rosterable, to_rosterable, ignore_capacity: false)
      if from_rosterable.is_a?(Lecture)
        from_rosterable = to_rosterable.conflicting_lecture_membership(user)
        unless from_rosterable
          return add_user!(user, to_rosterable, ignore_capacity: ignore_capacity).present?
        end
      end
      return false if from_rosterable == to_rosterable
      unless from_rosterable.lecture == to_rosterable.lecture
        raise(ArgumentError, "A move stays within one lecture")
      end

      lock_rosterables_in_order(from_rosterable, to_rosterable) do
        if from_rosterable.enrolls_in_lecture? || to_rosterable.enrolls_in_lecture?
          from_rosterable.lecture.lock!
        end
        raise(MoveWithoutEffectError) unless user_in_roster?(user, from_rosterable)
        raise(MoveLeavesLectureError) if leaves_last_place?(user, from_rosterable, to_rosterable)

        ensure_no_grading_data!(user, from_rosterable)

        removed = remove_user_without_lock!(user, from_rosterable)
        added   = add_user_without_lock!(user, to_rosterable, ignore_capacity: ignore_capacity)

        raise(MoveWithoutEffectError) unless removed && added
      end
      RosterNotificationMailer.moved(user, from_rosterable, to_rosterable)
      true
    rescue MoveWithoutEffectError
      false
    end

    private

      def leaves_lecture?(user, rosterable, lecture)
        leave = LectureLeave.new(lecture, user)
        rosterable == lecture ? leave.enrolled? : leave.only_place?(rosterable)
      end

      def leaves_last_place?(user, from_rosterable, to_rosterable)
        return false unless from_rosterable.enrolls_in_lecture?
        return false if to_rosterable.enrolls_in_lecture?

        lecture = from_rosterable.lecture
        lecture.present? && LectureLeave.new(lecture, user).only_place?(from_rosterable)
      end

      def on_a_list?(user, lecture)
        Cohort.lists_by_user(lecture, [user.id]).key?(user.id)
      end

      # Only rosterables that *are* the assessable can lose a result this way —
      # a talk or an exam owns its assessment, so leaving it means leaving the
      # gradebook behind. A tutorial is merely where a result is graded; the
      # assessment belongs to the assignment and survives the move.
      # Removing someone from a lecture also removes them from its talks and
      # exams, which fails if they have a result there. Checking here first
      # gives a clear error instead of a failure further down.
      def ensure_no_grading_data!(user, rosterable)
        assessment = rosterable.try(:assessment)
        held = assessment&.grading_data_for_user?(user)
        held ||= rosterable.is_a?(Lecture) &&
                 rosterable.graded_talk_and_exam_titles_by_user([user.id]).any?
        return unless held

        error = rosterable.is_a?(Lecture) ? LectureGradingDataPresentError : GradingDataPresentError
        raise(error,
              "#{rosterable.class.name} #{rosterable.id} holds grading data " \
              "for user #{user.id}")
      end

      def user_in_roster?(user, rosterable)
        rosterable.roster_entries.exists?(rosterable.roster_user_id_column => user.id)
      end

      def add_user_without_lock!(user, rosterable, ignore_capacity: false,
                                 override_rejection_in: nil)
        return if user_in_roster?(user, rosterable)

        ensure_uniqueness!(user, rosterable)

        unless ignore_capacity || within_capacity?(rosterable)
          raise(CapacityExceededError,
                "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
        end

        membership = rosterable.add_user_to_roster!(user)
        rosterable.propagate_to_lecture!([user.id])
        update_registration_materialization(user,
                                            rosterable,
                                            override_rejection_in: override_rejection_in)
        membership
      end

      def remove_user_without_lock!(user, rosterable, by: nil, keep_list_ids: [])
        removed = if rosterable.is_a?(Lecture)
          rosterable.remove_user_from_roster!(user, by: by)
        else
          rosterable.remove_user_from_roster!(user)
        end
        cascade_removal_from_subgroups!(user, rosterable, keep_list_ids)
        if removed && rosterable.is_a?(Lecture) && !on_a_list?(user, rosterable)
          user.unbookmark_lecture!(rosterable)
        end
        removed
      end

      def lock_rosterables_in_order(*rosterables, &)
        ActiveRecord::Base.transaction(requires_new: true) do
          sorted_rosterables = rosterables.uniq.sort_by { |r| [r.class.name, r.id.to_i] }
          lock_rosterables_recursively(sorted_rosterables, 0, &)
        end
      end

      def lock_rosterables_recursively(sorted_rosterables, index, &)
        if index >= sorted_rosterables.length
          yield
        else
          sorted_rosterables[index].with_lock do
            lock_rosterables_recursively(sorted_rosterables, index + 1, &)
          end
        end
      end

      def within_capacity?(rosterable)
        return true unless rosterable.respond_to?(:capacity)
        return true if rosterable.capacity.nil?

        rosterable.roster_entries.count < rosterable.capacity
      end

      def update_registration_materialization(user, rosterable, override_rejection_in: nil)
        now = Time.current

        Registration::Item.where(registerable: rosterable).find_each do |item|
          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user: user)
              .update_all(materialized_at: now)
          # rubocop:enable Rails/SkipsModelValidations
        end

        return if override_rejection_in.blank?

        # rubocop:disable Rails/SkipsModelValidations
        Registration::UserRegistration.rejected
                                      .where(user: user,
                                             registration_campaign_id: override_rejection_in,
                                             rejection_overridden_at: nil)
                                      .update_all(rejection_overridden_at: now,
                                                  updated_at: now)
        # rubocop:enable Rails/SkipsModelValidations
      end

      def ensure_uniqueness!(user, rosterable)
        conflicting = rosterable.conflicting_lecture_membership(user)
        return unless conflicting

        raise(UserAlreadyInBundleError, conflicting)
      end

      def cascade_removal_from_subgroups!(user, rosterable, keep_list_ids)
        return unless rosterable.is_a?(Lecture)

        rosterable.tutorials.find_each do |tutorial|
          tutorial.remove_user_from_roster!(user)
        end

        rosterable.talks.find_each do |talk|
          talk.remove_user_from_roster!(user)
        end

        kept = rosterable.cohorts.where(id: keep_list_ids, propagate_to_lecture: false)
        rosterable.cohorts.where.not(id: kept.select(:id)).find_each do |cohort|
          cohort.remove_user_from_roster!(user)
        end

        rosterable.exams.find_each do |exam|
          exam.remove_user_from_roster!(user)
        end
      end
  end
end
