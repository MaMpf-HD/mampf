module Rosters
  class MaintenanceService
    # Manages manual roster operations (add, remove, move) while enforcing capacity
    # constraints and ensuring transactional integrity
    class CapacityExceededError < StandardError; end
    class GradingDataPresentError < StandardError; end
    class NotEnrolledError < StandardError; end

    # Raised to unwind the move. ActiveRecord::Rollback cannot do that job here:
    # the nested with_lock transactions swallow it and commit anyway.
    class MoveWithoutEffectError < StandardError; end

    def add_user!(user, rosterable, force: false, source_campaign_id: nil)
      added = rosterable.with_lock do
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
    # Enrollment follows the places: whoever loses their last place leaves
    # the lecture with it, everything they had there included (see
    # LectureLeave#only_place?), so that nobody stays enrolled without one.
    # The group is locked before the lecture, as leaving the lecture does.
    # Returns the roster the user was taken off, the lecture in that case,
    # or nil.
    def remove_user!(user, rosterable, notify: true, by: nil)
      lecture = rosterable.lecture if place?(rosterable)
      left = ActiveRecord::Base.transaction do
        withdraw_registrations!(user, rosterable)
        rosterable.lock!
        lecture&.lock!
        last = lecture && LectureLeave.new(lecture, user).only_place?(rosterable)
        ensure_no_grading_data!(user, rosterable)
        ensure_no_grading_data!(user, lecture) if last
        next unless remove_user_without_lock!(user, rosterable, by: by)
        next rosterable unless last

        remove_user_without_lock!(user, lecture, by: by)
        lecture
      end
      RosterNotificationMailer.removed(user, left) if left && notify
      left
    end

    # Moves out of the target's conflicting_lecture_membership when asked to
    # move out of the lecture itself, or only adds to the target without one:
    # leaving the lecture on the way would take the person's lists,
    # registrations and bookmark along.
    def move_user!(user, from_rosterable, to_rosterable, force: false)
      if from_rosterable.is_a?(Lecture)
        from_rosterable = to_rosterable.conflicting_lecture_membership(user)
        return add_user!(user, to_rosterable, force: force).present? unless from_rosterable
      end
      return false if from_rosterable == to_rosterable

      lock_rosterables_in_order(from_rosterable, to_rosterable) do
        raise(MoveWithoutEffectError) unless user_in_roster?(user, from_rosterable)
        raise(MoveWithoutEffectError) if leaves_last_place?(user, from_rosterable, to_rosterable)

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

      def place?(rosterable)
        LectureLeave.place?(rosterable)
      end

      # A move onto a list or an exam would take the last place without
      # anything that enrolls in its stead.
      def leaves_last_place?(user, from_rosterable, to_rosterable)
        return false unless place?(from_rosterable) && !place?(to_rosterable)

        lecture = from_rosterable.lecture
        lecture.present? && LectureLeave.new(lecture, user).only_place?(from_rosterable)
      end

      # An exam list takes the lecture's members only, as registering for it
      # does (see Exam#registrable_by?); whoever is to sit it without a
      # tutorial comes in through a group first.
      def ensure_enrolled_for_exam!(user, rosterable)
        return unless rosterable.is_a?(Exam)
        return if rosterable.lecture.lecture_memberships.exists?(user: user)

        raise(NotEnrolledError,
              "User #{user.id} is not enrolled in lecture #{rosterable.lecture_id}")
      end

      # Withdraws the registrations of someone removed from a lecture, lest a
      # finalization put them back into its groups or exam lists. Before the
      # lecture is locked, since finalization locks its campaign first.
      def withdraw_registrations!(user, rosterable)
        return unless rosterable.is_a?(Lecture)
        return unless rosterable.lecture_memberships.exists?(user: user)

        UserPlaces.new(user).withdraw_registrations!([rosterable])
      end

      # Only rosterables that *are* the assessable can lose a result this way —
      # a talk or an exam owns its assessment, so leaving it means leaving the
      # gradebook behind. A tutorial is merely where a result is graded; the
      # assessment belongs to the assignment and survives the move.
      # A lecture's removal cascades into its talks and exams, and one graded
      # for the person refuses; asked here first, the refusal reads as this
      # service's, not as a crash further down.
      def ensure_no_grading_data!(user, rosterable)
        assessment = rosterable.try(:assessment)
        held = assessment&.grading_data_for_user?(user)
        held ||= rosterable.is_a?(Lecture) && graded_on_a_talk_or_exam?(user, rosterable)
        return unless held

        raise(GradingDataPresentError,
              "#{rosterable.class.name} #{rosterable.id} holds grading data " \
              "for user #{user.id}")
      end

      # The person's rows on the lecture's talks and exams at once, not one
      # query per talk or exam.
      def graded_on_a_talk_or_exam?(user, lecture)
        assessments = Assessment::Assessment
                      .where(assessable: lecture.talks)
                      .or(Assessment::Assessment.where(assessable: lecture.exams))
        Assessment::Participation
          .where(user: user, assessment: assessments)
          .includes(:task_points, :assessment)
          .any? { |row| row.assessment.grading_data_for?(row) }
      end

      def user_in_roster?(user, rosterable)
        rosterable.roster_entries.exists?(rosterable.roster_user_id_column => user.id)
      end

      def add_user_without_lock!(user, rosterable, force: false, source_campaign_id: nil)
        return if user_in_roster?(user, rosterable)

        ensure_uniqueness!(user, rosterable)
        ensure_enrolled_for_exam!(user, rosterable)

        unless force || within_capacity?(rosterable)
          raise(CapacityExceededError,
                "Capacity exceeded for #{rosterable.class.name} #{rosterable.id}")
        end

        membership = rosterable.add_user_to_roster!(user)
        propagate_to_lecture!(user, rosterable)
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

      def propagate_to_lecture!(user, rosterable)
        return unless place?(rosterable)

        lecture = rosterable.lecture
        return unless lecture.is_a?(Lecture)
        return if lecture == rosterable

        lecture.ensure_roster_membership!([user.id])
      end

      # Removal from a lecture takes every group, lists without enrollment
      # too, and the exam lists; the bookmark goes with the seat.
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
