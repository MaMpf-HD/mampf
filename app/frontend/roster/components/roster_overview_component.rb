# Renders a list of groups (tutorials, exams, etc.) for a lecture.
# Can be filtered by group_type (:tutorials, :exams, :all).
class RosterOverviewComponent < ViewComponent::Base
  # Central configuration for supported types.
  # Maps the group_type symbol to the model class name string and roster association.
  SUPPORTED_TYPES = {
    tutorials: { model: "Tutorial", association: :tutorial_memberships },
    talks: { model: "Talk", association: :speaker_talk_joins },
    cohorts: { model: "Cohort", association: :cohort_memberships }
  }.freeze

  def initialize(lecture:, group_type: :all, active_tab: :groups, rosterable: nil)
    super()
    @lecture = lecture
    @group_type = group_type
    @active_tab = active_tab
    @rosterable = rosterable
  end

  attr_reader :lecture, :active_tab, :rosterable, :group_type

  # Returns the officially enrolled participants (Lecture Superset).
  # Used for the 'Participants' tab.
  def participants
    @participants ||= @lecture.lecture_memberships
                              .joins(:user)
                              .includes(:user)
                              .order(
                                Arel.sql(
                                  "COALESCE(NULLIF(users.name_in_tutorials, ''), users.name) ASC"
                                )
                              )
  end

  # Checks if a participant is assigned to any functional sub-group (Tutorial or Talk).
  # Returns :assigned or :unassigned.
  # Note: Cohorts (Waitlists) do not count as 'assigned' for structure purposes.
  def participant_status(user)
    # Check if user is in any group that is NOT a Cohort
    is_assigned = user_memberships[user.id].any? do |group_id|
      group = all_groups_map[group_id]
      group && !group.is_a?(Cohort)
    end

    is_assigned ? :assigned : :unassigned
  end

  # Returns participants who are assigned to at least one functional group
  def assigned_participants
    @assigned_participants ||= participants.select { |m| participant_status(m.user) == :assigned }
  end

  # Returns participants who are not assigned to any functional group
  def unassigned_participants
    @unassigned_participants ||= participants.select do |m|
      participant_status(m.user) == :unassigned
    end
  end

  # Returns groups compatible for assignment for a specific user
  # Logic: (All Groups) - (Locked Groups) - (User's Current Groups)
  def available_groups_for(user)
    reserved_ids = user_memberships[user.id]

    all_assignable_groups.reject do |g|
      g.locked? || reserved_ids.include?(group_key(g))
    end
  end

  # Returns the groups the user is currently a member of (including Cohorts)
  def participant_groups(user)
    ids = user_memberships[user.id]
    ids.filter_map { |id| all_groups_map[id] }.sort_by(&:title)
  end

  # Returns all available actions (Add and/or Switch) for a target group
  # For partition types (Tutorial): Only "Switch" if user is already in one
  # For multi-membership types (Cohort, Talk): Both "Add" and "Switch" options
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

  # DEPRECATED: Use available_groups_for(user) instead.
  # Kept momentarily to avoid breaking until view is updated.
  def available_groups_for_participant
    available_groups_for(nil) # This won't work correctly, but we are updating the view.
  end

  # Returns a list of groups to display based on the selected type.
  # Structure: { title: String, items: ActiveRecord::Relation, type: Symbol }
  def groups
    @groups ||= target_types.filter_map { |type| build_group_data(type) }
  end

  def total_participants
    groups.sum do |group|
      group[:items].sum { |item| item.roster_entries.size }
    end
  end

  def group_type_title
    if @group_type.is_a?(Array) || @group_type == :all
      I18n.t("roster.tabs.group_maintenance")
    elsif SUPPORTED_TYPES.key?(@group_type)
      I18n.t("roster.tabs.#{@group_type.to_s.singularize}_maintenance")
    else
      I18n.t("roster.dashboard.title")
    end
  end

  # Helper to generate the correct polymorphic path
  def group_path(item)
    method_name = "#{item.model_name.singular_route_key}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  def active_campaign_for(item)
    item.registration_items.map(&:registration_campaign).find { |c| !c.completed? }
  end

  def show_campaign_running_badge?(item, campaign)
    !item.manual_roster_mode? && campaign.present? && item.roster_empty?
  end

  def campaign_badge_props(campaign)
    if campaign&.draft?
      { text: I18n.t("roster.campaign_draft"), css_class: "badge bg-secondary" }
    else
      { text: I18n.t("roster.campaign_running"), css_class: "badge bg-info text-dark" }
    end
  end

  def show_manual_mode_switch?(item)
    (item.manual_roster_mode? && item.can_disable_manual_mode?) ||
      (!item.manual_roster_mode? && item.can_enable_manual_mode?)
  end

  def toggle_manual_mode_path(item)
    method_name = "#{item.class.name.underscore}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  private

    def fetch_assigned_user_ids
      ids = Set.new

      # Users in tutorials
      ids.merge(TutorialMembership.where(tutorial: @lecture.tutorials).pluck(:user_id))

      # Users in talks (if applicable)
      if @lecture.talks.exists?
        ids.merge(SpeakerTalkJoin.where(talk: @lecture.talks).pluck(:speaker_id))
      end

      ids
    end

    def all_assignable_groups
      @all_assignable_groups ||= begin
        groups = []
        groups.concat(@lecture.tutorials.to_a) if @lecture.respond_to?(:tutorials)
        groups.concat(@lecture.talks.to_a) if @lecture.respond_to?(:talks)
        groups.concat(@lecture.cohorts.to_a) if @lecture.respond_to?(:cohorts)
        groups.sort_by(&:title)
      end
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

        # Bulk load Tutorial memberships
        if @lecture.tutorials.exists?
          TutorialMembership.where(tutorial: @lecture.tutorials)
                            .pluck(:user_id, :tutorial_id)
                            .each { |uid, tid| map[uid].add("Tutorial-#{tid}") }
        end

        # Bulk load Talk memberships
        if @lecture.talks.exists?
          SpeakerTalkJoin.where(talk: @lecture.talks)
                         .pluck(:speaker_id, :talk_id)
                         .each { |uid, tid| map[uid].add("Talk-#{tid}") }
        end

        # Bulk load Cohort memberships
        if @lecture.respond_to?(:cohorts) && @lecture.cohorts.exists?
          CohortMembership.where(cohort: @lecture.cohorts)
                          .pluck(:user_id, :cohort_id)
                          .each { |uid, cid| map[uid].add("Cohort-#{cid}") }
        end

        map
      end
    end

    def target_types
      if @group_type == :all
        SUPPORTED_TYPES.keys
      elsif @group_type.is_a?(Array)
        @group_type
      else
        [@group_type]
      end
    end

    def build_group_data(type)
      config = SUPPORTED_TYPES[type]
      items = @lecture.public_send(type)
                      .includes(config[:association], registration_items: :registration_campaign)

      return nil if items.empty?

      # Sort items: those with manual mode switch at the bottom
      sorted_items = items.sort_by do |item|
        if type == :talks
          item.position
        else
          has_switch = (item.manual_roster_mode? && item.can_disable_manual_mode?) ||
                       (!item.manual_roster_mode? && item.can_enable_manual_mode?)
          [has_switch ? 1 : 0, item.title]
        end
      end

      klass = config[:model].constantize

      {
        title: klass.model_name.human(count: 2),
        items: sorted_items,
        type: type
      }
    end
end
