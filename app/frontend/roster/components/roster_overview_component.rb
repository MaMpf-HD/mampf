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

  def show_manual_mode_switch?(item)
    (item.manual_roster_mode? && item.can_disable_manual_mode?) ||
      (!item.manual_roster_mode? && item.can_enable_manual_mode?)
  end

  def toggle_manual_mode_path(item)
    method_name = "#{item.class.name.underscore}_roster_path"
    Rails.application.routes.url_helpers.public_send(method_name, item)
  end

  def update_self_materialization_path(item, mode, group_type_param = nil)
    method_name = "#{item.class.name.underscore}_update_self_materialization_path"
    params = { self_materialization_mode: mode }
    params[:group_type] = group_type_param if group_type_param.present?
    Rails.application.routes.url_helpers.public_send(method_name, item, params)
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
