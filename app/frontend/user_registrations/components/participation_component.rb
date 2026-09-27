# Lists a student's groups, exams, pending allocations and rejections in a
# lecture. A campaign still open for registration shows the student's
# standing in its own row, so that standing is left out here.
class ParticipationComponent < ViewComponent::Base
  include EligibilityHelper
  include UserRegistrationsHelper

  TARGET = "student_registration_participation".freeze

  Row = Struct.new(:label, :title, :lines, :badge, :note, :actions, :tasks,
                   keyword_init: true)
  TaskResult = Struct.new(:label, :points, :max_points, keyword_init: true)

  def initialize(lecture:, user:, overview: nil)
    super()
    @lecture = lecture
    @user = user
    @overview = overview || UserRegistrations::LectureOverview.new(lecture, user)
  end

  def render?
    rows.any?
  end

  def rows
    @rows ||= roster_rows + standing_rows + rejection_rows + excluded_exam_rows
  end

  private

    def rosterables
      @rosterables ||= Array(
        Rosters::StudentMaterializedResultResolver.new(@user)
                                                 .all_rosterized_for_lecture(@lecture)
      )
    end

    def roster_rows
      rosterables.map do |rosterable|
        result = released_result(rosterable)
        Row.new(label: helpers.roster_type_text(rosterable),
                title: rosterable.title,
                lines: meta_lines(rosterable) + result_lines(result),
                badge: result ? result_badge(result) : roster_badge(rosterable),
                note: preference_note(rosterable),
                actions: leave_action(rosterable),
                tasks: result_tasks(result))
      end
    end

    # The student's own row of an exam or talk, once the lecturer has
    # published the results.
    def released_result(rosterable)
      return unless rosterable.is_a?(Exam) || rosterable.is_a?(Talk)

      participation = rosterable.assessment&.assessment_participations
                                &.includes(:task_points, assessment: :tasks)
                                &.find_by(user_id: @user.id)
      participation if participation&.result_released?
    end

    def result_badge(result)
      return [:warn, t("registration.user_registration.participation.absent")] if result.absent?
      return [:info, t("registration.user_registration.participation.exempt")] if result.exempt?

      grade = result_grade(result)
      return [:info, t("registration.user_registration.participation.grade", grade: grade)] if grade

      [:info, t("registration.user_registration.participation.marked")]
    end

    # A no-show may carry a grade too, so the grade is named beside "absent".
    def result_lines(result)
      return [] unless result

      grade = result_grade(result)
      lines = []
      if result.absent? && grade
        lines << t("registration.user_registration.participation.grade", grade: grade)
      end
      lines << points_line(result) if result.reviewed? && result.assessment.tasks.any?
      lines
    end

    def result_grade(result)
      return result.grade_text.presence unless result.grade_numeric

      helpers.number_with_precision(result.grade_numeric, precision: 1)
    end

    def points_line(result)
      t("registration.user_registration.participation.points",
        points: format_points(result.points_total || 0),
        total: format_points(result.assessment.effective_total_points))
    end

    def result_tasks(result)
      return [] unless result&.reviewed?

      points = result.task_points.index_by(&:task_id)
      result.assessment.tasks.sort_by(&:position).each_with_index.map do |task, index|
        TaskResult.new(label: task.description.presence ||
                              t("registration.user_registration.participation.problem",
                                number: index + 1),
                       points: points[task.id]&.points&.then { |value| format_points(value) },
                       max_points: format_points(task.max_points || 0))
      end
    end

    def format_points(value)
      helpers.number_with_precision(value, precision: 2, strip_insignificant_zeros: true)
    end

    def standing_rows
      @overview.standings.reject { |standing| standing.campaign.open_for_registrations? }
               .flat_map do |standing|
        next [preferences_row(standing)] if standing.kind == :preferences

        standing.registrations.filter_map do |registration|
          registerable = registration.registration_item.registerable
          next if registerable.in?(rosterables)

          registered_row(registration)
        end
      end
    end

    def preferences_row(standing)
      campaign = standing.campaign
      wishes = standing.registrations.map do |registration|
        ranked_title(registration)
      end
      Row.new(label: campaign.student_facing_title,
              title: t("registration.user_registration.participation.preferences_title"),
              lines: [wishes.join(" · ").presence].compact,
              badge: [:info, t("registration.user_registration.participation.allocation_pending")])
    end

    def registered_row(registration)
      registerable = registration.registration_item.registerable
      Row.new(label: helpers.roster_type_text(registerable),
              title: registerable.title,
              lines: meta_lines(registerable),
              badge: [:ok, t("registration.user_registration.participation.registered")],
              note: t("registration.user_registration.participation.checked_at_finalization"))
    end

    def rejection_rows
      capacity_rejection_rows + policy_rejection_rows + manual_rejection_rows
    end

    def capacity_rejection_rows
      rejected_campaigns(Registration::UserRegistration.with_capacity_rejection_reason)
        .map do |campaign, registrations|
          wishes = registrations.sort_by { |r| r.preference_rank.to_i }
                                .map { |r| ranked_title(r) }
          Row.new(label: campaign.student_facing_title,
                  title: t("registration.user_registration.participation.no_place"),
                  lines: [t("registration.user_registration.participation.your_preferences",
                            preferences: wishes.join(", "))],
                  badge: [:bad, t("registration.user_registration.participation.no_place")])
        end
    end

    def policy_rejection_rows
      rejected_campaigns(Registration::UserRegistration.with_policy_rejection_reason)
        .map do |campaign, _registrations|
          messages = failed_policy_messages(campaign).presence ||
                     [t("registration.user_registration.status.rejected")]
          Row.new(label: campaign.student_facing_title,
                  title: t("registration.user_registration.participation.rejected"),
                  lines: messages,
                  badge: [:bad, t("registration.user_registration.participation.rejected")])
        end
    end

    def manual_rejection_rows
      scope = Registration::UserRegistration.where(
        rejection_reason_type: Registration::UserRegistration::REJECTION_REASON_TYPE_MANUAL
      )
      rejected_campaigns(scope).map do |campaign, registrations|
        label = registrations.filter_map(&:rejection_reason_label).first
        Row.new(label: campaign.student_facing_title,
                title: t("registration.user_registration.participation.rejected"),
                lines: [label.presence ||
                        t("registration.user_registration.participation.rejected_by_teacher")],
                badge: [:bad, t("registration.user_registration.participation.rejected")])
      end
    end

    # Finalized campaigns in which this kind of rejection is not overridden and
    # the student has no pending or confirmed registration.
    def rejected_campaigns(scope)
      active_ids = Registration::UserRegistration.where(user_id: @user.id,
                                                        status: [:confirmed, :pending])
                                                 .select(:registration_campaign_id)
      Registration::UserRegistration.rejected.not_overridden.merge(scope)
                                    .where(user_id: @user.id)
                                    .joins(:registration_campaign)
                                    .where(registration_campaigns: {
                                             campaignable_type: "Lecture",
                                             campaignable_id: @lecture.id,
                                             status: Registration::Campaign.statuses[:completed]
                                           })
                                    .where.not(registration_campaign_id: active_ids)
                                    .includes(:registration_campaign, :registration_item)
                                    .group_by(&:registration_campaign)
    end

    def excluded_exam_rows
      exams = @lecture.exams.where(id: ExamRosterEntry.excluded.where(user_id: @user.id)
                                                              .select(:exam_id))
      exams.map do |exam|
        Row.new(label: helpers.roster_type_text(exam),
                title: exam.title,
                lines: meta_lines(exam),
                badge: [:bad, t("registration.user_registration.participation.excluded_from_exam")])
      end
    end

    def failed_policy_messages(campaign)
      UserRegistrations::FinalizedRejectionTraceService.new(campaign, @user).call
                                                       .filter_map do |entry|
        next entry[:fallback_label] if entry.key?(:fallback_label)

        eligibility_failure_message(entry, user: @user, context: :finalization_rejection)
      end.uniq
    end

    def meta_lines(rosterable)
      case rosterable
      when Tutorial
        [helpers.roster_tutors_text(rosterable).presence, rosterable.location.presence].compact
      when Talk
        [rosterable.dates&.compact&.map { |d| l(d.to_date) }&.join(", ").presence].compact
      when Exam
        [rosterable.date && format_date(rosterable.date),
         rosterable.location.presence].compact
      when Cohort
        [rosterable.description.presence].compact
      else
        []
      end
    end

    def roster_badge(rosterable)
      case rosterable
      when Exam then [:ok, t("registration.user_registration.participation.on_exam_list")]
      when Cohort then [:info, t("registration.user_registration.participation.enrolled")]
      else [:ok, t("registration.user_registration.participation.assigned")]
      end
    end

    def leave_action(rosterable)
      return unless rosterable.allow_self_remove?(@user)

      helpers.button_to(t("registration.user_registration.participation.leave"),
                        helpers.public_send("self_remove_#{rosterable.class.name.underscore}_path",
                                            rosterable.id),
                        method: :delete, class: "btn btn-sm btn-outline-secondary")
    end

    def preference_note(rosterable)
      membership = rosterable.roster_entries.includes(:source_campaign)
                             .find_by(rosterable.roster_user_id_column => @user.id)
      campaign = membership&.source_campaign
      return unless campaign&.preference_based?

      registrations = @overview.registrations_for(campaign).select(&:preference_rank)
                               .sort_by(&:preference_rank)
      return if registrations.empty?

      fulfilled = registrations.find { |r| r.registration_item.registerable == rosterable }
      if fulfilled
        t("registration.user_registration.participation.preference_fulfilled",
          rank: rank_label(fulfilled.preference_rank))
      else
        t("registration.user_registration.participation.outside_preferences")
      end
    end

    def ranked_title(registration)
      [rank_label(registration.preference_rank),
       registration.registration_item.title].compact.join(" ")
    end

    def rank_label(rank)
      return if rank.blank?

      t("registration.user_registration.preference_rank_options.#{rank}")
    end
end
