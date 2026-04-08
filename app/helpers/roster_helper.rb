module RosterHelper
  def roster_panel_path(registerable)
    public_send(
      "#{registerable.model_name.singular}_roster_path",
      registerable, source: :panel, format: :turbo_stream
    )
  end

  def roster_edit_group_path(registerable)
    opts = roster_group_type_param(registerable)
    public_send("edit_#{registerable.model_name.singular}_path",
                registerable, **opts)
  end

  def roster_delete_group_path(registerable)
    opts = roster_group_type_param(registerable)
    public_send("#{registerable.model_name.singular}_path",
                registerable, **opts)
  end

  def roster_add_member_path(registerable, **)
    public_send("add_member_#{registerable.model_name.singular}_path",
                registerable, **)
  end

  def roster_move_member_path_template(registerable)
    public_send("move_member_#{registerable.model_name.singular}_path",
                registerable, "__USER_ID__")
  end

  def roster_remove_member_path(registerable, user, **)
    public_send("remove_member_#{registerable.model_name.singular}_path",
                registerable, user, **)
  end

  def roster_update_self_materialization_path(registerable, mode:)
    public_send(
      "update_self_materialization_#{registerable.model_name.singular}_path",
      registerable, mode: mode
    )
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
      "#{Talk.model_name.human} #{registerable.position}"
    else
      I18n.t("registration.item.types.tutorial")
    end
  end

  private

    def roster_group_type_param(registerable)
      gt = registerable.roster_group_type
      gt == :talks ? {} : { group_type: gt }
    end

  public

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

  def roster_group_badge(group, _group_type)
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

  def rosterable_display_type(rosterable)
    case rosterable.class.name
    when "Tutorial"
      t("registration.item.types.tutorial")
    when "Talk"
      "#{t("registration.item.types.talk")} #{item.registerable.position}"
    when "Cohort"
      cohort = item.registerable
      base_type = t("registration.item.types.other_group")

      if cohort.propagate_to_lecture
        base_type
      else
        icon = tag.i(class: "bi bi-person-x ms-1",
                     style: "color: #495057;",
                     data: { bs_toggle: "tooltip",
                             bs_title: t("registration.item.hints.no_propagation") })
        safe_join([base_type, " ", icon])
      end
    end
  end

  def self_add_path
    case type
    when "Tutorial"
      Rails.application.routes.url_helpers.self_add_tutorial_path(id)
    when "Talk"
      Rails.application.routes.url_helpers.self_add_talk_path(id)
    when "Cohort"
      Rails.application.routes.url_helpers.self_add_cohort_path(id)
    end
  end

  def self_remove_path
    case type
    when "Tutorial"
      Rails.application.routes.url_helpers.self_remove_tutorial_path(id)
    when "Talk"
      Rails.application.routes.url_helpers.self_remove_talk_path(id)
    when "Cohort"
      Rails.application.routes.url_helpers.self_remove_cohort_path(id)
    end
  end

  def format_date(time)
    return "" if time.nil?

    time.strftime("%b %d, %H:%M")
  end
  SELF_ROSTER_TABLE_CONFIG = {
    "Tutorial" => [
      { header: "basics.tutor",
        cell_class: "text-start fw-semibold",
        icon: "person",
        field: ->(rosterable) { rosterable.tutor_names } }
    ],
    "Talk" => [
      { header: "basics.position",
        cell_class: "text-end",
        icon: "looks_one",
        field: ->(rosterable) { rosterable.position } },
      { header: "basics.date",
        icon: "event",
        field: lambda { |rosterable|
          rosterable.dates&.map do |d|
            format_date(d)
          end&.join(", ")
        } }
    ],
    "Cohort" => [
      { header: "basics.description",
        icon: "description",
        cell_class: "text-center",
        field: ->(rosterable) { rosterable.description } }
    ]
  }.freeze
end
