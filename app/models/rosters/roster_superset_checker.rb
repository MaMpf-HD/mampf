module Rosters
  class RosterSupersetChecker
    class RosterSupersetViolationError < StandardError; end

    def check_all_lectures!
      Rails.logger.info("[RosterSupersetChecker] Starting nightly check")

      total_lectures = 0
      total_violations = 0

      lectures_to_check = relevant_lectures

      lectures_to_check.find_each do |lecture|
        total_lectures += 1

        lecture_ids = lecture_user_ids(lecture)
        group_ids = propagating_group_user_ids(lecture)

        violations = find_violations(lecture, lecture_ids, group_ids)

        if violations.any?
          total_violations += violations.size
          log_violation(lecture, violations)
        end
      end

      Rails.logger.info("[RosterSupersetChecker] Completed: " \
                        "checked #{total_lectures} lectures, " \
                        "found #{total_violations} violations")

      return unless total_violations.positive?

      raise(RosterSupersetViolationError,
            "Found #{total_violations} user(s) missing from lecture rosters " \
            "(checked #{total_lectures} lectures). Check logs for details.")
    end

    private

      # Returns lectures from the active term and the next term.
      # This scopes validation to currently relevant lectures, avoiding
      # unnecessary checks on historical/archived data.
      def relevant_lectures
        active_term = Term.active
        return Lecture.none if active_term.blank?

        term_ids = [active_term.id]
        term_ids << active_term.next&.id if active_term.next.present?

        Lecture.where(term_id: term_ids)
      end

      def lecture_user_ids(lecture)
        lecture.lecture_memberships.pluck(:user_id).uniq
      end

      def propagating_group_user_ids(lecture)
        # We intentionally skip SpeakerTalkJoins here. Historical seminars
        # created before lecture-level rosters existed have speakers in talks
        # but not in lecture rosters, which would cause false positives.
        tutorial_ids = TutorialMembership
                       .joins(:tutorial)
                       .where(tutorials: { lecture_id: lecture.id })
                       .pluck(:user_id)

        cohort_ids = CohortMembership
                     .joins(:cohort)
                     .where(cohorts: { context_type: "Lecture",
                                       context_id: lecture.id,
                                       propagate_to_lecture: true })
                     .pluck(:user_id)

        (tutorial_ids + cohort_ids).uniq
      end

      def find_violations(lecture, lecture_ids, group_ids)
        missing_ids = group_ids - lecture_ids
        return [] if missing_ids.empty?

        users_by_id = User.where(id: missing_ids)
                          .index_by(&:id)

        tutorial_groups =
          lecture.tutorials
                 .joins(:tutorial_memberships)
                 .where(tutorial_memberships: { user_id: missing_ids })
                 .select("tutorials.id, tutorials.title, tutorial_memberships.user_id")
                 .group_by(&:user_id)

        cohort_groups = lecture.cohorts
                               .where(propagate_to_lecture: true)
                               .joins(:cohort_memberships)
                               .where(cohort_memberships: { user_id: missing_ids })
                               .select("cohorts.id, cohorts.title, cohort_memberships.user_id")
                               .group_by(&:user_id)

        missing_ids.map do |user_id|
          user = users_by_id[user_id]
          groups = []

          tutorial_groups[user_id]&.each do |tutorial|
            groups << "Tutorial: #{tutorial.title}"
          end

          cohort_groups[user_id]&.each do |cohort|
            groups << "Cohort: #{cohort.title}"
          end

          {
            user_id: user_id,
            user_email: user&.email || "Unknown",
            found_in_groups: groups
          }
        end
      end

      def log_violation(lecture, violations)
        return if violations.empty?

        log_data = {
          timestamp: Time.current.iso8601,
          lecture_id: lecture.id,
          lecture_title: lecture.title,
          violation_count: violations.size,
          violations: violations
        }

        Rails.logger.error("[RosterSupersetViolation] #{log_data.to_json}")

        Rails.logger.error("Lecture #{lecture.id} (#{lecture.title}): " \
                           "#{violations.size} user(s) missing from roster")

        violations.each do |v|
          Rails.logger.error("  - User #{v[:user_id]} (#{v[:user_email]}): " \
                             "in #{v[:found_in_groups].join(", ")}")
        end
      end
  end
end
