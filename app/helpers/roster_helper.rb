module RosterHelper
  def group_title_with_capacity(group)
    count = if group.respond_to?(:roster_entries_count)
      group.roster_entries_count
    else
      group.roster_entries.count
    end
    "#{group.title} (#{count}/#{group.capacity || "∞"})"
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
    if !item.locked?
      link_to(component.group_path(item),
              class: "btn btn-sm btn-outline-primary",
              title: t("roster.tooltips.manage_participants"),
              data: { bs_toggle: "tooltip" }) do
        tag.i(class: "bi bi-person-lines-fill")
      end
    elsif campaign
      link_to(edit_lecture_path(component.lecture, tab: "campaigns", campaign_id: campaign.id),
              class: "btn btn-sm btn-outline-secondary",
              title: t("roster.view_campaign"),
              data: { turbo_frame: "_top", bs_toggle: "tooltip" }) do
        tag.i(class: "bi bi-calendar-check")
      end
    elsif !item.in_campaign?
      link_to(edit_lecture_path(component.lecture, tab: "campaigns", new_campaign: true),
              class: "btn btn-sm btn-outline-secondary",
              title: t("roster.create_campaign"),
              data: { turbo_frame: "_top", bs_toggle: "tooltip" }) do
        tag.i(class: "bi bi-calendar-plus")
      end
    end
  end

  def roster_edit_button(item, group_type)
    link_to(edit_polymorphic_path(item, group_type: group_type),
            class: "btn btn-sm btn-outline-primary",
            title: t("roster.tooltips.edit_settings"),
            data: { turbo_stream: true, bs_toggle: "tooltip" }) do
      tag.i(class: "bi bi-tools")
    end
  end

  def roster_destroy_button(item, group_type)
    return unless item.destructible?

    link_to(polymorphic_path(item, group_type: group_type),
            data: { turbo_method: :delete, turbo_confirm: t("confirmation.generic"),
                    bs_toggle: "tooltip" },
            title: t("roster.tooltips.delete"),
            class: "btn btn-sm btn-outline-danger") do
      tag.i(class: "bi bi-trash")
    end
  end

  def cohort_type_options(cohort = nil)
    available_types = if cohort&.persisted?
      Cohort::TYPE_TO_PURPOSE.select do |_type, purpose|
        case purpose
        when :enrollment
          cohort.propagate_to_lecture?
        when :planning
          !cohort.propagate_to_lecture?
        when :general
          true
        end
      end.keys
    else
      Cohort::TYPE_TO_PURPOSE.keys
    end

    available_types.map do |type|
      [t("registration.item.types.#{type.parameterize(separator: "_")}"), type]
    end
  end

  def cohort_type_from_purpose(purpose)
    Cohort::TYPE_TO_PURPOSE.key(purpose&.to_sym) || "Other Group"
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
