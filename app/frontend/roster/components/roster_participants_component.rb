# Renders the "Participants" tab in the Roster UI.
# Manages the list of students on the lecture roster, their assignment status,
# and actions to assign/move them.
class RosterParticipantsComponent < ViewComponent::Base
  SECTION_TARGETS = {
    view_switch: "roster_participants_view_switch",
    campaign_switch: "roster_participants_campaign_switch",
    top_nav: "roster_participants_top_nav",
    header_controls: "roster_participants_header_controls",
    results: "roster_participants_results"
  }.freeze

  SECTION_PARTIALS = {
    view_switch: "roster/components/roster_participants_view_switch",
    campaign_switch: "roster/components/roster_participants_campaign_switch",
    top_nav: "roster/components/roster_participants_top_nav",
    header_controls: "roster/components/roster_participants_header_controls",
    results: "roster/components/roster_participants_results"
  }.freeze

  REGISTRATIONS_PARTIAL = "roster/components/roster_participants_registrations".freeze
  LEFT_PARTIAL = "roster/components/roster_participants_left".freeze
  COUNT_KEYS = { "enrolled" => :total, "registered" => :registered, "left" => :left }.freeze

  def self.section_targets
    SECTION_TARGETS
  end

  def self.section_partials
    SECTION_PARTIALS
  end

  # rubocop:disable Metrics/ParameterLists
  def initialize(lecture:, group_type:, participants: nil, pagy: nil, view: "enrolled",
                 campaign: nil, search_string: nil, counts: {}, section: :full)
    super()
    @lecture = lecture
    @group_type = group_type
    @participants = participants
    @pagy = pagy
    @view = view || "enrolled"
    @campaign = campaign
    @search_string = search_string
    @counts = counts
    @section = section
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :lecture, :group_type, :pagy, :view, :campaign, :search_string, :counts,
              :section

  # Returns the officially enrolled participants (Lecture Superset), or in the
  # registered view the users with a running registration.
  def participants
    @participants ||= []
  end

  def filtered?
    search_string.present?
  end

  # In this view, the participants are users with a running registration
  # rather than lecture memberships.
  def registered_view?
    view == "registered"
  end

  def enrolled_view?
    view == "enrolled"
  end

  def left_view?
    view == "left"
  end

  def view_count(name)
    counts[COUNT_KEYS.fetch(name)] || 0
  end

  def left_description(membership)
    date = l(membership.excluded_at.to_date)
    if membership.left_by_self?
      t("roster.left.by_self", date: date)
    elsif membership.excluded_by
      t("roster.left.by_staff", date: date, name: membership.excluded_by.name)
    else
      t("roster.left.removed", date: date)
    end
  end

  # The groups the staff can add someone who has left to, as select options:
  # a group a running registration process manages takes nobody by hand.
  def readmission_options
    @readmission_options ||= helpers.roster_enrolling_group_options(lecture)
  end

  def registration_entry(user)
    @registration_entry_by_user ||=
      Rosters::RunningRegistrations.new(lecture, campaign: campaign)
                                   .entry_by_user(participants.map(&:id))
    @registration_entry_by_user[user.id]
  end

  # Pairs each running campaign with the number of people the search finds
  # there, so the selector shows where a search hits.
  def running_campaigns
    @running_campaigns ||= begin
      running = Rosters::RunningRegistrations.new(lecture, search: search_string)
      counts = running.counts_by_campaign
      running.campaigns.includes(:registration_items).map { |c| [c, counts.fetch(c.id, 0)] }
    end
  end

  def registration_state(entry)
    if entry.allocated?
      item = entry.allocated_item
      return t("roster.registrations.states.not_allocated") unless item

      t("roster.registrations.states.allocated", group: item.title)
    elsif entry.campaign.preference_based?
      t("roster.registrations.states.awaiting_allocation")
    elsif entry.registrations.any?(&:confirmed?)
      t("roster.registrations.states.confirmed")
    else
      t("roster.registrations.states.pending")
    end
  end

  # Names the places an empty search result points to, as [label, hits]: the
  # other view and, in the registered view, the other running campaigns.
  def search_hits_elsewhere
    return [] if search_string.blank?

    others = COUNT_KEYS.keys - [view]
    hits = others.map { |name| [t("roster.views.#{name}"), view_count(name)] }
    if registered_view?
      hits += running_campaigns.reject { |c, _| c == campaign }
                               .map { |c, n| [c.student_facing_title, n] }
    end
    hits.select { |_, n| n.to_i.positive? }
  end

  # Counts people in a group without enrollment who are missing from this
  # list, since a lecturer finds them in the group and expects them here.
  def outside_enrollment_count
    @outside_enrollment_count ||=
      CohortMembership.joins(:cohort)
                      .merge(Cohort.for_lectures(lecture).where(propagate_to_lecture: false))
                      .where.not(user_id: lecture.lecture_memberships.select(:user_id))
                      .distinct.count(:user_id)
  end

  def program_columns
    if registered_view?
      registered = Rosters::RunningRegistrations.new(lecture, campaign: campaign).people
      return { t("roster.views.registered") => ProgramDistribution.new(registered) }
    end
    if left_view?
      left = User.where(id: lecture.excluded_lecture_memberships.select(:user_id))
      return { t("roster.views.left") => ProgramDistribution.new(left) }
    end

    enrolled = User.where(id: lecture.lecture_memberships.select(:user_id))
    { t("roster.programs.enrolled") => ProgramDistribution.new(enrolled) }
  end

  # Returns the groups the user is currently a member of, cohorts and exam
  # lists included: an exam list is a place in the lecture too.
  def participant_groups(user)
    ids = user_memberships[user.id]
    ids.filter_map { |id| all_groups_map[id] }.sort_by(&:title)
  end

  def kick_confirmation(user)
    exams = exam_titles_by_user[user.id]
    return t("roster.warnings.confirm_kick_from_lecture") if exams.blank?

    t("roster.warnings.confirm_kick_from_lecture_exams", exams: exams.to_sentence)
  end

  # Returns the HTML for the pagination navigation (top and bottom)
  # Uses Pagy with custom querify logic to preserve tabs and filters.
  def pagination_nav
    return unless @pagy && @pagy.pages > 1

    helpers.pagy_series_nav(@pagy,
                            path: helpers.lecture_roster_participants_path(@lecture),
                            anchor_string: 'data-turbo-stream="true"',
                            querify: lambda { |p|
                              p["view"] = @view unless enrolled_view?
                              p["campaign"] = @campaign.id if @campaign
                              p["search"] = @search_string if @search_string.present?
                              p["group_type"] =
                                if @group_type.is_a?(Array)
                                  @group_type.map(&:to_s)
                                else
                                  @group_type.to_s
                                end
                            })
  end

  def section?(section_name)
    section == section_name
  end

  def section_target(section_name)
    self.class.section_targets.fetch(section_name)
  end

  def section_component(next_section)
    self.class.new(**section_kwargs, section: next_section)
  end

  def section_partial
    return REGISTRATIONS_PARTIAL if section == :results && registered_view?
    return LEFT_PARTIAL if section == :results && left_view?

    self.class.section_partials.fetch(section)
  end

  private

    def exam_titles_by_user
      @exam_titles_by_user ||=
        ExamRosterEntry.exam_titles_by_user(@lecture, participants.map(&:user_id))
    end

    def section_kwargs
      { lecture: lecture, group_type: group_type, participants: participants,
        pagy: pagy, view: view, campaign: campaign,
        search_string: search_string, counts: counts }
    end

    def all_assignable_groups
      @all_assignable_groups ||=
        [].concat(@lecture.tutorials.includes(:tutorial_memberships,
                                              registration_items: :registration_campaign).to_a)
          .concat(@lecture.talks.includes(:speaker_talk_joins,
                                          registration_items: :registration_campaign).to_a)
          .concat(@lecture.cohorts.includes(:cohort_memberships,
                                            registration_items: :registration_campaign).to_a)
          .concat(@lecture.exams.to_a)
          .sort_by(&:title)
    end

    def all_groups_map
      @all_groups_map ||= all_assignable_groups.index_by { |g| group_key(g) }
    end

    def group_key(group)
      "#{group.class.name}-#{group.id}"
    end

    # Pre-fetches all memberships for the lecture to avoid N+1 queries
    # Returns: Hash { user_id => Set<group_id> }
    def user_memberships
      @user_memberships ||= begin
        map = Hash.new { |h, k| h[k] = Set.new }

        # OPTIMIZE: Only fetch memberships for users on the current page
        user_ids = participants.map(&:user_id)

        if user_ids.any?
          # Bulk load Tutorial memberships
          if @lecture.tutorials.exists?
            TutorialMembership.joins(:tutorial)
                              .where(tutorials: { lecture_id: @lecture.id }, user_id: user_ids)
                              .pluck(:user_id, :tutorial_id)
                              .each { |uid, tid| map[uid].add("Tutorial-#{tid}") }
          end

          # Bulk load Talk memberships
          if @lecture.talks.exists?
            SpeakerTalkJoin.joins(:talk)
                           .where(talks: { lecture_id: @lecture.id }, speaker_id: user_ids)
                           .pluck(:speaker_id, :talk_id)
                           .each { |uid, tid| map[uid].add("Talk-#{tid}") }
          end

          # Bulk load Cohort memberships
          if @lecture.cohorts.exists?
            CohortMembership.joins(:cohort)
                            .where(cohorts: { context_id: @lecture.id,
                                              context_type: "Lecture" }, user_id: user_ids)
                            .pluck(:user_id, :cohort_id)
                            .each { |uid, cid| map[uid].add("Cohort-#{cid}") }
          end

          ExamRosterEntry.active.where(exam: @lecture.exams, user_id: user_ids)
                         .pluck(:user_id, :exam_id)
                         .each { |uid, eid| map[uid].add("Exam-#{eid}") }
        end

        map
      end
    end
end
