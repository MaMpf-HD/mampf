# Lists a student's groups, exams, pending allocations and rejections in a
# lecture. A campaign still open for registration shows the student's
# standing in its own row, so that standing is left out here.
class ParticipationComponent < ViewComponent::Base
  include EligibilityHelper
  include UserRegistrationsHelper

  TARGET = "student_registration_participation".freeze

  Row = Struct.new(:label, :title, :lines, :badge, :note, :actions, :tasks,
                   keyword_init: true)

  def initialize(lecture:, user:, overview: nil)
    super()
    @lecture = lecture
    @user = user
    @overview = overview || UserRegistrations::LectureOverview.new(lecture, user)
    @leave = Rosters::LectureLeave.new(lecture, user)
  end

  def leave_dialog
    LeaveLectureComponent.new(lecture: @lecture, leave: @leave)
  end

  def render?
    rows.any?
  end

  def rows
    @rows ||= lecture_rows + roster_rows + standing_rows + rejection_rows +
              excluded_exam_rows
  end

  private

    def rosterables
      @rosterables ||= Array(
        Rosters::StudentMaterializedResultResolver.new(@user)
                                                 .all_rosterized_for_lecture(@lecture)
      )
    end

    def lecture_rows
      return [] unless @leave.participating?

      [Row.new(label: @lecture.sort_localized,
               title: @lecture.course.title,
               lines: [],
               badge: lecture_badge,
               actions: leave_lecture_action)]
    end

    def lecture_badge
      return unless @leave.enrolled?

      [:info, t("registration.user_registration.participation.enrolled")]
    end

    def leave_lecture_action
      helpers.button_tag(t("lecture_home.leave.button"),
                         type: "button",
                         class: "btn btn-sm border-0 bg-danger-subtle text-danger-emphasis",
                         data: { bs_toggle: "modal",
                                 bs_target: "##{LeaveLectureComponent::ID}" })
    end

    def roster_rows
      rosterables.map do |rosterable|
        result = released_result(rosterable)
        Row.new(label: helpers.roster_type_text(rosterable),
                title: rosterable.title,
                lines: meta_lines(rosterable) + result_lines(result) +
                       [only_group_line(rosterable)].compact,
                badge: result ? result_badge(result) : roster_badge(rosterable),
                note: preference_note(rosterable),
                actions: leave_action(rosterable),
                tasks: result&.tasks || [])
      end
    end

    def released_result(rosterable)
      return unless rosterable.is_a?(Exam) || rosterable.is_a?(Talk)

      participation = rosterable.assessment&.assessment_participations
                                &.includes(:task_points, assessment: :tasks)
                                &.find_by(user_id: @user.id)
      ResultSummary.new(participation) if participation&.result_released?
    end

    def result_badge(result)
      return [:warn, t("registration.user_registration.participation.absent")] if result.absent?
      return [:info, t("registration.user_registration.participation.exempt")] if result.exempt?
      return [:info, result.grade_line] if result.grade

      [:info, t("registration.user_registration.participation.marked")]
    end

    def result_lines(result)
      result ? result.lines : []
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
      return if only_group?(rosterable)

      helpers.button_to(leave_label(rosterable),
                        helpers.public_send("self_remove_#{rosterable.class.name.underscore}_path",
                                            rosterable.id),
                        method: :delete, class: "btn btn-sm btn-outline-secondary",
                        form: { data: { turbo_confirm: leave_confirmation(rosterable) } })
    end

    # An enrolled student leaves their last place only by leaving the
    # lecture, so the row says so instead of offering the button.
    def only_group?(rosterable)
      @leave.only_place?(rosterable)
    end

    def only_group_line(rosterable)
      return unless rosterable.allow_self_remove?(@user) && only_group?(rosterable)

      t("registration.user_registration.participation.only_group")
    end

    def leave_label(rosterable)
      kind = { Tutorial => "tutorial", Talk => "talk" }.fetch(rosterable.class, "group")
      t("registration.user_registration.participation.leave_#{kind}")
    end

    # Says whether the way back is open: a group that only lets students leave
    # takes them back through its staff alone. Leaving a group keeps the
    # lecture, which students do not expect, so it says that too.
    def leave_confirmation(rosterable)
      notes = []
      notes << "leave_no_sheets" if rosterable.is_a?(Tutorial)
      notes << "leave_stays_enrolled" if @leave.enrolled?
      [leave_confirmation_base(rosterable),
       *notes.map { |note| t("registration.user_registration.participation.#{note}") }]
        .join(" ")
    end

    def leave_confirmation_base(rosterable)
      t("registration.user_registration.participation.leave_confirm_#{rejoin_key(rosterable)}",
        group: rosterable.title)
    end

    def rejoin_key(rosterable)
      if !rosterable.config_allow_self_add?
        "final"
      elsif rosterable.capacity
        "while_free"
      else
        "rejoin"
      end
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
