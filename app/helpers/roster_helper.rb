module RosterHelper
  def group_title_with_capacity(group)
    count = if group.respond_to?(:roster_entries_count)
      group.roster_entries_count
    else
      group.roster_entries.count
    end
    "#{group.title} (#{count}/#{group.capacity || "∞"})"
  end

  def should_display_cohort_purpose?(cohort)
    cohort.purpose.present? && cohort.purpose != "general"
  end

  def item_overbooked?(item)
    return false unless item.capacity

    item.roster_entries.count > item.capacity
  end

  def tutor_names_with_fallback(tutorial)
    tutorial.tutor_names.presence || "TBA"
  end

  def roster_group_types(lecture)
    if lecture.seminar?
      [:talks, :cohorts]
    else
      [:tutorials, :cohorts]
    end
  end

  def roster_maintenance_frame_id(group_type)
    suffix = group_type.is_a?(Array) ? group_type.join("_") : group_type
    "roster_maintenance_#{suffix}"
  end

  def hidden_group_type_field(group_type)
    if group_type.is_a?(Array)
      safe_join(group_type.map { |t| hidden_field_tag("group_type[]", t) })
    else
      hidden_field_tag(:group_type, group_type)
    end
  end

  def roster_manage_button(item, component, campaign)
    locked = item.locked?

    if locked
      tooltip = if campaign
        t("roster.tooltips.locked_manage")
      else
        t("roster.tooltips.locked_manage_no_campaign")
      end
      tag.span(title: tooltip,
               data: { bs_toggle: "tooltip" }) do
        tag.button(class: "btn btn-sm btn-outline-primary disabled opacity-50",
                   style: "cursor: not-allowed;",
                   disabled: true) do
          tag.i(class: "bi bi-person-lines-fill")
        end
      end
    else
      link_to(component.group_path(item),
              class: "btn btn-sm btn-primary",
              title: t("roster.tooltips.manage_participants"),
              data: { bs_toggle: "tooltip" }) do
        tag.i(class: "bi bi-person-lines-fill")
      end
    end
  end

  def roster_campaign_button(item, component, campaign)
    if campaign
      # Active campaign - show view campaign button
      link_to(edit_lecture_path(component.lecture, tab: "campaigns",
                                                   campaign_id: campaign.id),
              class: "btn btn-sm btn-secondary",
              title: t("roster.view_campaign"),
              data: { turbo_frame: "_top", bs_toggle: "tooltip" }) do
        tag.i(class: "bi bi-calendar-event")
      end
    elsif item.in_campaign?
      # Has campaign history - show view campaign button for most recent
      recent_campaign = item.registration_items
                            .joins(:registration_campaign)
                            .order("registration_campaigns.created_at DESC")
                            .first
                            &.registration_campaign

      if recent_campaign
        link_to(edit_lecture_path(component.lecture, tab: "campaigns",
                                                     campaign_id: recent_campaign.id),
                class: "btn btn-sm btn-secondary",
                title: t("roster.view_campaign"),
                data: { turbo_frame: "_top", bs_toggle: "tooltip" }) do
          tag.i(class: "bi bi-calendar-event")
        end
      end
    else
      # Never in campaign - show create campaign button (disabled if skip_campaigns is true)
      can_create = !item.skip_campaigns?
      if can_create
        link_to(edit_lecture_path(component.lecture, tab: "campaigns", new_campaign: true),
                class: "btn btn-sm btn-secondary",
                title: t("roster.create_campaign"),
                data: { turbo_frame: "_top", bs_toggle: "tooltip" }) do
          tag.i(class: "bi bi-calendar-plus")
        end
      else
        tag.span(title: t("roster.tooltips.create_campaign_disabled"),
                 data: { bs_toggle: "tooltip" }) do
          tag.button(class: "btn btn-sm btn-outline-secondary disabled opacity-50",
                     style: "cursor: not-allowed;",
                     disabled: true) do
            tag.i(class: "bi bi-calendar-plus")
          end
        end
      end
    end
  end

  def roster_edit_button(item, group_type)
    link_to(edit_polymorphic_path(item, group_type: group_type),
            class: "btn btn-sm btn-primary",
            title: t("roster.tooltips.edit_settings"),
            data: { turbo_stream: true, bs_toggle: "tooltip" }) do
      tag.i(class: "bi bi-tools")
    end
  end

  def roster_destroy_button(item, group_type)
    disabled = !item.destructible?
    tooltip = if disabled
      t("roster.tooltips.delete_disabled")
    else
      t("roster.tooltips.delete")
    end

    if disabled
      tag.span(title: tooltip, data: { bs_toggle: "tooltip" }) do
        tag.button(class: "btn btn-sm btn-outline-danger opacity-50",
                   style: "cursor: not-allowed;",
                   disabled: true,
                   type: "button") do
          tag.i(class: "bi bi-trash")
        end
      end
    else
      link_to(polymorphic_path(item, group_type: group_type),
              data: { turbo_method: :delete, turbo_confirm: t("confirmation.generic"),
                      bs_toggle: "tooltip" },
              title: tooltip,
              class: "btn btn-sm btn-danger") do
        tag.i(class: "bi bi-trash")
      end
    end
  end

  def self_materialization_state(item, campaign)
    active_campaign = campaign && !campaign.completed?
    disabled = active_campaign || (!item.skip_campaigns? && !item.in_campaign?)

    tooltip = if active_campaign
      t("roster.tooltips.self_materialization_disabled_campaign")
    elsif !item.skip_campaigns? && !item.in_campaign?
      t("roster.tooltips.self_materialization_disabled_fresh")
    else
      t("roster.self_materialization.label")
    end

    { disabled: disabled, tooltip: tooltip }
  end

  def skip_campaigns_state(item)
    can_skip = item.can_skip_campaigns?
    can_unskip = item.can_unskip_campaigns?
    disabled = !(item.skip_campaigns? ? can_unskip : can_skip)
    icon_class = item.skip_campaigns? ? "bi-calendar-x" : "bi-calendar-check"

    tooltip = if disabled
      if item.skip_campaigns?
        t("roster.disable_skip_campaigns_hint")
      else
        t("roster.enable_skip_campaigns_hint")
      end
    elsif item.skip_campaigns?
      t("roster.tooltips.skip_campaigns_enabled")
    else
      t("roster.tooltips.skip_campaigns_disabled")
    end

    { disabled: disabled, tooltip: tooltip, icon_class: icon_class }
  end

  def roster_group_badge(group, group_type)
    isolating = group.is_a?(Cohort) && !group.propagate_to_lecture?
    # Use secondary (gray) for normal propagating groups to reduce visual noise.
    # Use light/border (ghost) for isolating groups to differentiate them.
    badge_class = isolating ? "bg-light text-dark border" : "bg-secondary text-white"

    link_to(group.title,
            polymorphic_path([group, :roster]),
            class: "badge #{badge_class} me-1 text-decoration-none",
            style: "cursor: pointer;",
            data: { turbo_frame: roster_maintenance_frame_id(group_type), turbo_prefetch: false })
  end
end
