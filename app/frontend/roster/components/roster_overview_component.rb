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

  attr_reader :lecture, :active_tab, :rosterable

  # Returns the officially enrolled participants (Lecture Superset).
  # Used for the 'Participants' tab.
  def participants
    @participants ||= @lecture.lecture_memberships
                              .joins(:user)
                              .includes(:user)
                              .order(Arel.sql("COALESCE(NULLIF(users.name_in_tutorials, ''), users.name) ASC"))
  end

  # Checks if a participant is assigned to any functional sub-group (Tutorial or Talk).
  # Returns :assigned or :unassigned.
  # Note: Cohorts (Waitlists) do not count as 'assigned' for structure purposes.
  def participant_status(user)
    @assigned_user_ids ||= fetch_assigned_user_ids
    @assigned_user_ids.include?(user.id) ? :assigned : :unassigned
  end

  # Returns the groups (Tutorials, Talks) a user is assigned to.
  def participant_groups(user)
    @participant_groups_cache ||= {}
    @participant_groups_cache[user.id] ||= begin
      groups = []
      groups.concat(@lecture.tutorials.joins(:tutorial_memberships)
                            .where(tutorial_memberships: { user_id: user.id }))
      groups.concat(@lecture.talks.joins(:speaker_talk_joins)
                            .where(speaker_talk_joins: { speaker_id: user.id }))
      groups
    end
  end

  # Returns all available groups for moving/assigning a participant.
  def available_groups_for_participant
    @available_groups_for_participant ||= begin
      groups = []
      groups.concat(@lecture.tutorials.to_a) if @lecture.tutorials.any?
      groups.concat(@lecture.talks.to_a) if @lecture.talks.any?
      groups.reject(&:locked?).sort_by(&:title)
    end
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
