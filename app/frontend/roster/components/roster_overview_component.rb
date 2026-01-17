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
    helpers.public_send(method_name, item)
  end

  def active_campaign_for(item)
    item.registration_items.map(&:registration_campaign).find { |c| !c.completed? }
  end

  def show_campaign_running_badge?(item, campaign)
    !item.skip_campaigns? && campaign.present? && item.roster_empty?
  end

  def show_skip_campaigns_switch?(item)
    (item.skip_campaigns? && item.can_unskip_campaigns?) ||
      (!item.skip_campaigns? && item.can_skip_campaigns?)
  end

  def toggle_skip_campaigns_path(item)
    method_name = "#{item.class.name.underscore}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  private

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

      # Sort items: those with skip_campaigns switch at the bottom
      sorted_items = items.sort_by do |item|
        has_switch = (item.skip_campaigns? && item.can_unskip_campaigns?) ||
                     (!item.skip_campaigns? && item.can_skip_campaigns?)
        [has_switch ? 1 : 0, item.title]
      end

      klass = config[:model].constantize

      {
        title: klass.model_name.human(count: 2),
        items: sorted_items,
        type: type
      }
    end
end
