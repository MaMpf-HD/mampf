module Rosters
  class RosterSupersetChecker
    class RosterSupersetViolationError < StandardError; end

    def check_all_lectures!
      Rails.logger.info("[RosterSupersetChecker] Starting nightly check")

      total_lectures = 0
      total_violations = 0

      Lecture.find_each do |lecture|
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
            "Found #{total_violations} roster superset violations across " \
            "#{total_lectures} lectures. Check logs for details.")
    end

    private

      def lecture_user_ids(lecture)
        lecture.lecture_memberships.pluck(:user_id).uniq
      end

      def propagating_group_user_ids(lecture)
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

        missing_ids.map do |user_id|
          user = User.find_by(id: user_id)
          groups = find_user_groups(lecture, user_id)

          {
            user_id: user_id,
            user_email: user&.email || "Unknown",
            found_in_groups: groups
          }
        end
      end

      def find_user_groups(lecture, user_id)
        groups = lecture.tutorials.joins(:tutorial_memberships)
                        .where(tutorial_memberships: { user_id: user_id }).map do |t|
          "Tutorial: #{t.title}"
        end

        lecture.cohorts.where(propagate_to_lecture: true)
               .joins(:cohort_memberships)
               .where(cohort_memberships: { user_id: user_id }).find_each do |c|
          groups << "Cohort: #{c.title}"
        end

        groups
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
