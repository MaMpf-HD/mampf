module RosterHelper
  def roster_panel_path(registerable)
    case registerable
    when Tutorial
      tutorial_roster_path(registerable, source: :panel,
                                         format: :turbo_stream)
    when Cohort
      cohort_roster_path(registerable, source: :panel,
                                       format: :turbo_stream)
    when Talk
      talk_roster_path(registerable, source: :panel,
                                     format: :turbo_stream)
    end
  end

  def roster_edit_group_path(registerable)
    case registerable
    when Tutorial then edit_tutorial_path(registerable, group_type: :tutorials)
    when Cohort   then edit_cohort_path(registerable, group_type: :cohorts)
    when Talk     then edit_talk_path(registerable)
    end
  end

  def roster_delete_group_path(registerable)
    case registerable
    when Tutorial then tutorial_path(registerable, group_type: :tutorials)
    when Cohort   then cohort_path(registerable, group_type: :cohorts)
    when Talk     then talk_path(registerable)
    end
  end

  def roster_add_member_path(registerable, **)
    case registerable
    when Tutorial then add_member_tutorial_path(registerable, **)
    when Cohort   then add_member_cohort_path(registerable, **)
    when Talk     then add_member_talk_path(registerable, **)
    end
  end

  def roster_move_member_path_template(registerable)
    case registerable
    when Tutorial then move_member_tutorial_path(registerable, "__USER_ID__")
    when Cohort   then move_member_cohort_path(registerable, "__USER_ID__")
    when Talk     then move_member_talk_path(registerable, "__USER_ID__")
    end
  end

  def roster_remove_member_path(registerable, user, **)
    case registerable
    when Tutorial
      remove_member_tutorial_path(registerable, user, **)
    when Cohort
      remove_member_cohort_path(registerable, user, **)
    end
  end

  def roster_update_self_materialization_path(registerable, mode:)
    case registerable
    when Tutorial
      update_self_materialization_tutorial_path(registerable, mode: mode)
    when Cohort
      update_self_materialization_cohort_path(registerable, mode: mode)
    when Talk
      update_self_materialization_talk_path(registerable, mode: mode)
    end
  end

  def roster_bulk_sm_path(registerable, mode:)
    lecture = registerable.try(:lecture) || registerable.try(:context)
    roster_bulk_update_self_materialization_lecture_path(lecture, mode: mode)
  end

  def roster_tutors_text(registerable)
    if registerable.respond_to?(:tutor_names)
      registerable.tutor_names.presence || I18n.t("basics.tba")
    elsif registerable.is_a?(Talk) && registerable.speakers.any?
      registerable.speakers.map(&:tutorial_name).join(", ")
    else
      I18n.t("basics.tba")
    end
  end

  def roster_type_text(registerable, item: nil)
    if registerable.is_a?(Cohort)
      I18n.t("roster.group_category.flexible_group")
    elsif item
      item_display_type(item)
    elsif registerable.is_a?(Talk)
      Talk.model_name.human
    else
      I18n.t("registration.item.types.tutorial")
    end
  end

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

  def roster_group_badge(group, group_type)
    isolating = group.is_a?(Cohort) && !group.propagate_to_lecture?
    # Use secondary (gray) for normal propagating groups to reduce visual noise.
    # Use light/border (ghost) for isolating groups to differentiate them.
    badge_class = isolating ? "bg-light text-dark border" : "bg-secondary text-white"

    lecture = group.is_a?(Cohort) && group.context_type == "Lecture" ? group.context : group.lecture

    link_to(group.title,
            edit_lecture_path(lecture, tab: "groups",
                                       open_roster: "#{group.class.name}-#{group.id}"),
            class: "badge #{badge_class} me-1 text-decoration-none",
            style: "cursor: pointer;",
            data: { turbo: false })
  end
end
