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

    def add_user!(user, rosterable, force: false, source_campaign_id: nil)
      added = rosterable.with_lock do
        rosterable.lecture&.lock! if rosterable.enrolls_in_lecture?
        add_user_without_lock!(user,
                               rosterable,
                               force: force,
                               source_campaign_id: source_campaign_id)
      end
      RosterNotificationMailer.added(user, rosterable) if added
      added
    end

    # A caller that removes the user within a larger transaction passes
    # notify: false, since the mail job is enqueued even if that transaction
    # rolls back.
    #
    # Someone who loses their last group that enrolls them also leaves the
    # lecture, and their registrations there are withdrawn. Returns the roster
    # they were taken off (the lecture in that case), or nil.
    #
    # Locks the campaigns, then the group, then the lecture, as finalization and
    # leaving do. The campaigns are locked even if the user seems to keep
    # another group: that is only certain under the group's lock, and locking
    # the campaigns only after the group would break that order. A caller that
    # locks the group itself must lock the campaigns first (see
    # SelfMaterializationService#self_remove!).
    def remove_user!(user, rosterable, notify: true, by: nil)
      lecture = rosterable.lecture if rosterable.is_a?(Lecture) || rosterable.enrolls_in_lecture?
      places = UserPlaces.new(user)
      left = ActiveRecord::Base.transaction do
        places.lock_campaigns!([lecture]) if lecture
        rosterable.lock!
        lecture&.lock!
        leaving = lecture.present? && leaves_lecture?(user, rosterable, lecture)
        also_leaves_lecture = leaving && lecture != rosterable
        ensure_no_grading_data!(user, rosterable)
        ensure_no_grading_data!(user, lecture) if also_leaves_lecture
        next unless remove_user_without_lock!(user, rosterable, by: by)
        next rosterable unless leaving

        remove_user_without_lock!(user, lecture, by: by) if also_leaves_lecture
        places.withdraw_registrations!([lecture])
        lecture
      end
      RosterNotificationMailer.removed(user, left) if left && notify
      left
    end

    # A move from the lecture to a group never takes the person out of the
    # lecture. It moves them out of the group that conflicts with the target,
    # or only adds them to the target if there is none.
    def move_user!(user, from_rosterable, to_rosterable, force: false)
      if from_rosterable.is_a?(Lecture)
        from_rosterable = to_rosterable.conflicting_lecture_membership(user)
        return add_user!(user, to_rosterable, force: force).present? unless from_rosterable
      end
      return false if from_rosterable == to_rosterable

      lock_rosterables_in_order(from_rosterable, to_rosterable) do
        [from_rosterable, to_rosterable].find(&:enrolls_in_lecture?)&.lecture&.lock!
        raise(MoveWithoutEffectError) unless user_in_roster?(user, from_rosterable)
        raise(MoveLeavesLectureError) if leaves_last_place?(user, from_rosterable, to_rosterable)

        ensure_no_grading_data!(user, from_rosterable)

        removed = remove_user_without_lock!(user, from_rosterable)
        added   = add_user_without_lock!(user, to_rosterable, force: force)

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

      def add_user_without_lock!(user, rosterable, force: false, source_campaign_id: nil)
        return if user_in_roster?(user, rosterable)

        ensure_uniqueness!(user, rosterable)

        unless force || within_capacity?(rosterable)
          raise(CapacityExceededError,
                "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
        end

        membership = rosterable.add_user_to_roster!(user)
        rosterable.propagate_to_lecture!([user.id])
        update_registration_materialization(user,
                                            rosterable,
                                            source_campaign_id: source_campaign_id)
        membership
      end

      def remove_user_without_lock!(user, rosterable, by: nil)
        removed = if rosterable.is_a?(Lecture)
          rosterable.remove_user_from_roster!(user, by: by)
        else
          rosterable.remove_user_from_roster!(user)
        end
        cascade_removal_from_subgroups!(user, rosterable)
        user.unbookmark_lecture!(rosterable) if removed && rosterable.is_a?(Lecture)
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

      def update_registration_materialization(user, rosterable, source_campaign_id: nil)
        now = Time.current

        Registration::Item.where(registerable: rosterable).find_each do |item|
          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user: user)
              .update_all(materialized_at: now)
          # rubocop:enable Rails/SkipsModelValidations
        end

        return if source_campaign_id.blank?

        # rubocop:disable Rails/SkipsModelValidations
        Registration::UserRegistration.rejected
                                      .where(user: user,
                                             registration_campaign_id: source_campaign_id,
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

      def cascade_removal_from_subgroups!(user, rosterable)
        return unless rosterable.is_a?(Lecture)

        rosterable.tutorials.find_each do |tutorial|
          tutorial.remove_user_from_roster!(user)
        end

        rosterable.talks.find_each do |talk|
          talk.remove_user_from_roster!(user)
        end

        rosterable.cohorts.find_each do |cohort|
          cohort.remove_user_from_roster!(user)
        end

        rosterable.exams.find_each do |exam|
          exam.remove_user_from_roster!(user)
        end
      end
  end
end
