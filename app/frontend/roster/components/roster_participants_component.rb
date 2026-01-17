# Renders the "Participants" tab in the Roster UI.
# Manages the list of students on the lecture roster, their assignment status,
# and actions to assign/move them.
class RosterParticipantsComponent < ViewComponent::Base
  # rubocop:disable Metrics/ParameterLists
  def initialize(lecture:, group_type:, participants: nil, pagy: nil, filter_mode: "all",
                 counts: {})
    super()
    @lecture = lecture
    @group_type = group_type
    @participants = participants
    @pagy = pagy
    @filter_mode = filter_mode
    @counts = counts
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :lecture, :group_type, :pagy, :filter_mode, :counts

  # Returns the officially enrolled participants (Lecture Superset).
  def participants
    @participants ||= []
  end

  # Returns participants who are assigned to at least one functional group
  def assigned_participants
    # Only applicable to current page
    @assigned_participants ||= participants.select { |m| participant_status(m.user) == :assigned }
  end

  # Returns participants who are not assigned to any functional group
  def unassigned_participants
    # Only applicable to current page
    @unassigned_participants ||= participants.select do |m|
      participant_status(m.user) == :unassigned
    end
  end

  # Checks if a participant is assigned to any functional sub-group (Tutorial or Talk).
  # Returns :assigned or :unassigned.
  def participant_status(user)
    # Check if user is in any group that is NOT a Cohort
    is_assigned = user_memberships[user.id].any? do |group_id|
      group = all_groups_map[group_id]
      group && !group.is_a?(Cohort)
    end

    is_assigned ? :assigned : :unassigned
  end

  # Returns the groups the user is currently a member of (including Cohorts)
  def participant_groups(user)
    ids = user_memberships[user.id]
    ids.filter_map { |id| all_groups_map[id] }.sort_by(&:title)
  end

  # Returns groups compatible for assignment for a specific user
  # Logic: (All Groups) - (Locked Groups) - (User's Current Groups)
  def available_groups_for(user)
    reserved_ids = user_memberships[user.id]

    all_assignable_groups.reject do |g|
      g.locked? || reserved_ids.include?(group_key(g))
    end
  end

  def available_transfer_targets_for(user)
    available = available_groups_for(user)
    return [] unless available.any?

    grouped = available.group_by(&:class)
    sorted_groups = grouped.sort_by { |klass, _| klass.name == "Cohort" ? 2 : 1 }

    sorted_groups.map do |klass, groups|
      {
        title: I18n.t("registration.item.groups.#{klass.name.underscore.pluralize}"),
        groups: groups.sort_by(&:title)
      }
    end
  end

  # Returns all available actions (Add and/or Switch) for a target group
  def assignment_actions(user, target_group)
    actions = []
    current_of_type = participant_groups(user).select { |g| g.instance_of?(target_group.class) }

    # Only Tutorial is a partition type (mutually exclusive)
    # Talk and Cohort allow multiple memberships
    is_partition_type = target_group.is_a?(Tutorial)

    if is_partition_type
      # For partition types: Only offer "Switch" if already in a group, otherwise "Add"
      if current_of_type.any?
        current_of_type.each do |source|
          actions << {
            url: helpers.public_send("move_member_#{source.class.name.underscore}_path",
                                     source, user),
            method: :patch,
            params: {
              target_id: target_group.id,
              target_type: target_group.class.name
            },
            label: t("roster.actions.switch_from_to",
                     from: source.title,
                     to: target_group.title),
            icon: "arrow-left-right"
          }
        end
      else
        actions << {
          url: helpers.public_send("add_member_#{target_group.model_name.singular_route_key}_path",
                                   target_group),
          method: :post,
          params: { email: user.email },
          label: t("roster.actions.add_to", to: target_group.title),
          icon: "plus-circle"
        }
      end
    else
      # For multi-membership types: Offer both "Add" and "Switch" options
      actions << {
        url: helpers.public_send("add_member_#{target_group.model_name.singular_route_key}_path",
                                 target_group),
        method: :post,
        params: { email: user.email },
        label: t("roster.actions.add_to", to: target_group.title),
        icon: "plus-circle"
      }

      current_of_type.each do |source|
        actions << {
          url: helpers.public_send("move_member_#{source.class.name.underscore}_path",
                                   source, user),
          method: :patch,
          params: {
            target_id: target_group.id,
            target_type: target_group.class.name
          },
          label: t("roster.actions.switch_from_to",
                   from: source.title,
                   to: target_group.title),
          icon: "arrow-left-right"
        }
      end
    end

    actions
  end

  # Helper to generate the correct polymorphic path
  # Copied from RosterOverviewComponent as it is needed for links here.
  def group_path(item)
    method_name = "#{item.model_name.singular_route_key}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  # Returns the HTML for the pagination navigation (top and bottom)
  # Uses Pagy with custom querify logic to preserve tabs and filters.
  def pagination_nav
    return unless @pagy && @pagy.pages > 1

    helpers.pagy_series_nav(@pagy,
                            path: helpers.lecture_roster_path(@lecture),
                            querify: lambda { |p|
                              p["tab"] = "participants"
                              p["filter"] = @filter_mode
                              p["group_type"] =
                                if @group_type.is_a?(Array)
                                  @group_type.map(&:to_s)
                                else
                                  @group_type.to_s
                                end
                            })
  end

  private

    def all_assignable_groups
      @all_assignable_groups ||=
        [].concat(@lecture.tutorials.includes(:tutorial_memberships,
                                              registration_items: :registration_campaign).to_a)
          .concat(@lecture.talks.includes(:speaker_talk_joins,
                                          registration_items: :registration_campaign).to_a)
          .concat(@lecture.cohorts.includes(:cohort_memberships,
                                            registration_items: :registration_campaign).to_a)
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
        end

        map
      end
    end
end
