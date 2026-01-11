# Renders a list of groups (tutorials, exams, etc.) for a lecture.
# Can be filtered by group_type (:tutorials, :exams, :all).
class RosterOverviewComponent < ViewComponent::Base
  # Central configuration for supported types.
  # Maps the group_type symbol to the model class name string and roster association.
  SUPPORTED_TYPES = {
    tutorials: { model: "Tutorial", association: :tutorial_memberships, includes: :tutors },
    talks: { model: "Talk", association: :speaker_talk_joins, includes: :speakers },
    cohorts: { model: "Cohort", association: :cohort_memberships, includes: [] }
  }.freeze

  # rubocop:disable Metrics/ParameterLists
  def initialize(lecture:, group_type: :all, active_tab: :groups, rosterable: nil,
                 participants: nil, pagy: nil, filter_mode: "all", counts: {})
    super()
    @lecture = lecture
    @group_type = group_type
    @active_tab = active_tab
    @rosterable = rosterable
    @participants = participants
    @pagy = pagy
    @filter_mode = filter_mode
    @counts = counts
  end
  # rubocop:enable Metrics/ParameterLists

  attr_reader :lecture, :active_tab, :rosterable, :group_type, :participants, :pagy, :filter_mode,
              :counts

  # Returns a list of groups to display based on the selected type.
  # Structure: { title: String, items: ActiveRecord::Relation, type: Symbol }
  def groups
    @groups ||= target_types.flat_map do |type|
      if type == :cohorts
        build_cohort_groups
      else
        [build_group_data(type)].compact
      end
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
    # Check loaded association first to avoid N+1 and direct DB hits
    items = if item.association(:registration_items).loaded?
      item.registration_items
    else
      item.registration_items.includes(:registration_campaign)
    end
    items.map(&:registration_campaign).find { |c| !c.completed? }
  end

  def show_skip_campaigns_switch?(item)
    (item.skip_campaigns? && item.can_unskip_campaigns?) ||
      (!item.skip_campaigns? && item.can_skip_campaigns?)
  end

  def toggle_skip_campaigns_path(item)
    method_name = "#{item.class.name.underscore}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  def update_self_materialization_path(item, mode, group_type_param = nil)
    method_name = "#{item.class.name.underscore}_update_self_materialization_path"
    group_type_param ||= @group_type
    Rails.application.routes.url_helpers.public_send(
      method_name,
      item,
      self_materialization_mode: mode,
      group_type: group_type_param
    )
  end

  def subtables_for(group)
    if group[:type] == :cohorts && group[:items].any?
      with_enrollment = group[:items].select(&:propagate_to_lecture?)
      without_enrollment = group[:items].reject(&:propagate_to_lecture?)

      [
        {
          title: I18n.t("roster.cohorts.with_lecture_enrollment_title"),
          help: I18n.t("roster.cohorts.with_lecture_enrollment_help"),
          items: with_enrollment
        },
        {
          title: I18n.t("roster.cohorts.without_lecture_enrollment_title"),
          help: I18n.t("roster.cohorts.without_lecture_enrollment_help"),
          items: without_enrollment
        }
      ].select { |p| p[:items].any? }
        .presence || [{ title: nil, items: group[:items] }]
    else
      [{ title: nil, items: group[:items] }]
    end
  end

  def primary_status(item, campaign)
    if campaign
      I18n.t("roster.status_texts.campaign_#{campaign.status}")
    elsif item.in_real_campaign?
      status = I18n.t("roster.status_texts.post_campaign")
      unless item.self_materialization_mode_disabled?
        status += " (#{I18n.t("roster.status_texts.self_enrollment")})"
        if bypasses_campaign_policy?(item, item.self_materialization_mode)
          status += " ⚠️ #{I18n.t("roster.status_texts.no_policy_enforcement")}"
        end
      end
      status
    elsif item.skip_campaigns?
      status = I18n.t("roster.status_texts.direct_management")
      unless item.self_materialization_mode_disabled?
        status += " (#{I18n.t("roster.status_texts.self_enrollment")})"
      end
      status
    else
      I18n.t("roster.status_texts.awaiting_setup")
    end
  end

  def bypasses_campaign_policy?(item, target_mode)
    return false if target_mode.to_s == "disabled"
    return false if target_mode.to_s == "remove_only"
    return false unless item.in_real_campaign?

    last_campaign = item.registration_items
                        .joins(:registration_campaign)
                        .merge(::Registration::Campaign.completed)
                        .order("registration_campaigns.updated_at DESC")
                        .first&.registration_campaign

    return false unless last_campaign

    last_campaign.registration_policies.exists?
  end

  def policy_bypass_warning_data(item, target_mode)
    return nil unless bypasses_campaign_policy?(item, target_mode)

    last_campaign = item.registration_items
                        .joins(:registration_campaign)
                        .merge(::Registration::Campaign.completed)
                        .order("registration_campaigns.updated_at DESC")
                        .first&.registration_campaign

    policies = last_campaign.registration_policies.active
    kinds = policies.limit(3).pluck(:kind)
    policy_names = kinds.map { |k| I18n.t("registration.policy.kinds.#{k}") }.join(", ")
    policy_names += "..." if policies.count > 3

    {
      policy_name: policy_names.presence || I18n.t("roster.unknown_policy"),
      campaign_name: last_campaign.description.presence || I18n.t("roster.completed_campaign")
    }
  end

  def campaign_has_policies?(campaign)
    return false unless campaign

    if campaign.association(:registration_policies).loaded?
      campaign.registration_policies.any?
    else
      campaign.registration_policies.exists?
    end
  end

  def policy_shield_tooltip(item, campaign)
    # Check active campaign first
    target_campaign = campaign

    # If no active campaign, check for completed campaign with policies
    if target_campaign.nil? && item.in_real_campaign?
      target_campaign = item.registration_items
                            .joins(:registration_campaign)
                            .merge(::Registration::Campaign.completed)
                            .order("registration_campaigns.updated_at DESC")
                            .first&.registration_campaign
    end

    return nil unless campaign_has_policies?(target_campaign)

    policies = target_campaign.registration_policies.active

    policy_kinds = if policies.loaded?
      policies.first(3).map { |p| I18n.t("registration.policy.kinds.#{p.kind}") }.join(", ")
    else
      kinds = policies.limit(3).pluck(:kind)
      kinds.map { |k| I18n.t("registration.policy.kinds.#{k}") }.join(", ")
    end

    count = policies.loaded? ? policies.size : policies.count
    policy_kinds += "..." if count > 3

    I18n.t("roster.status_texts.gated_by_policies", policies: policy_kinds)
  end

  def status_badge_data(item, campaign)
    if campaign
      campaign_badge_data(campaign)
    elsif item.in_real_campaign?
      tooltip_text = I18n.t("roster.status_texts.post_campaign")
      has_policies = campaign_has_policies_for_item?(item)

      if has_policies
        policy_tooltip = policy_shield_tooltip(item, nil)
        tooltip_text += " • #{policy_tooltip}" if policy_tooltip
      end

      {
        icon: "bi-check-circle-fill",
        text: I18n.t("roster.status_texts.post_campaign_short") + (has_policies ? " 🛡️" : ""),
        css_class: "bg-light text-secondary border border-secondary",
        tooltip: tooltip_text,
        self_enrollment: !item.self_materialization_mode_disabled?
      }
    elsif item.skip_campaigns?
      {
        icon: "bi-gear-fill",
        text: I18n.t("roster.status_texts.direct_management_short"),
        css_class: "bg-light text-primary border border-primary",
        tooltip: I18n.t("roster.status_texts.direct_management"),
        self_enrollment: !item.self_materialization_mode_disabled?
      }
    else
      {
        icon: "bi-hourglass",
        text: I18n.t("roster.status_texts.awaiting_setup_short"),
        css_class: "bg-light text-muted border border-secondary",
        tooltip: I18n.t("roster.status_texts.awaiting_setup"),
        self_enrollment: false
      }
    end
  end

  def campaign_badge_data(campaign)
    icon, css_class = case campaign.status
                      when "open"
                        ["bi-calendar-check", "bg-light text-success border border-success"]
                      when "closed"
                        ["bi-calendar-x", "bg-light text-warning border border-warning"]
                      when "processing"
                        ["bi-arrow-repeat", "bg-light text-primary border border-primary"]
                      when "completed"
                        ["bi-calendar-check-fill",
                         "bg-light text-secondary border border-secondary"]
                      else
                        ["bi-calendar", "bg-light text-secondary border border-secondary"]
    end

    {
      icon: icon,
      text: I18n.t("roster.status_texts.campaign_#{campaign.status}_short"),
      css_class: css_class,
      tooltip: I18n.t("roster.status_texts.campaign_#{campaign.status}"),
      self_enrollment: false
    }
  end

  def self_enrollment_badge_data(item)
    mode = item.self_materialization_mode
    icon, text = case mode
                 when "add_only"
                   ["bi-person-plus-fill", "+"]
                 when "remove_only"
                   ["bi-person-dash-fill", "−"]
                 when "add_and_remove"
                   ["bi-person-fill-add", "±"]
                 else
                   ["bi-person", ""]
    end

    has_warning = bypasses_campaign_policy?(item, mode)
    tooltip_text = I18n.t("roster.self_materialization.modes.#{mode}")

    tooltip_text += " ⚠️ #{I18n.t("roster.status_texts.no_policy_enforcement")}" if has_warning

    {
      icon: icon,
      text: text,
      css_class: "bg-light text-success border border-success",
      tooltip: tooltip_text,
      has_warning: has_warning
    }
  end

  def campaign_has_policies_for_item?(item)
    return false unless item.in_real_campaign?

    last_campaign = item.registration_items
                        .joins(:registration_campaign)
                        .merge(::Registration::Campaign.completed)
                        .order("registration_campaigns.updated_at DESC")
                        .first&.registration_campaign

    return false unless last_campaign

    campaign_has_policies?(last_campaign)
  end

  private

    def target_types
      if @group_type == :all
        SUPPORTED_TYPES.keys
      elsif @group_type.is_a?(Array)
        @group_type.map(&:to_sym)
      else
        [@group_type.to_sym]
      end
    end

    def build_cohort_groups
      # Filter for access groups or sidecars if needed,
      # but returning all in one table per user request.

      # Use eager loaded associations and sort in memory
      items = @lecture.cohorts.sort_by(&:title)

      # Removed early return to ensure "Add" button is always visible
      # even if no cohorts exist yet.

      [{
        type: :cohorts,
        title: Cohort.model_name.human(count: 2),
        items: items,
        link: Rails.application.routes.url_helpers.new_cohort_path(lecture_id: @lecture.id,
                                                                   format: :turbo_stream,
                                                                   group_type: @group_type)
      }]
    end

    def build_group_data(type)
      config = SUPPORTED_TYPES[type]
      # Using public_send returns the pre-loaded association target (Array) because
      # we eager loaded it in controller
      items = @lecture.public_send(type)

      return nil if items.empty?

      # Sort items: completed campaigns first, then others, each subgroup sorted by title
      sorted_items = items.sort_by do |item|
        if type == :talks
          item.position
        else
          has_completed_campaign = item.in_real_campaign? && !item.campaign_active?
          [has_completed_campaign ? 0 : 1, item.title.to_s]
        end
      end

      klass = config[:model].constantize

      {
        title: klass.model_name.human(count: 2),
        items: sorted_items,
        type: type,
        link: Rails.application.routes.url_helpers.public_send(
          "new_#{config[:model].underscore}_path",
          lecture_id: @lecture.id,
          format: :turbo_stream,
          group_type: @group_type
        )
      }
    end
end
