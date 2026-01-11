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

  def show_campaign_running_badge?(item, campaign)
    !item.skip_campaigns? && campaign.present? && item.roster_empty?
  end

  def campaign_badge_props(campaign)
    if campaign&.draft?
      { text: I18n.t("roster.campaign_draft"), css_class: "badge bg-secondary" }
    else
      { text: I18n.t("roster.campaign_running"), css_class: "badge bg-info text-dark" }
    end
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
