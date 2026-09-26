# This component renders a row for a roster group (tutorial, talk or cohort)
# in the Groups tab. A click on the row opens the group's roster in the side
# panel, and the row is a drop target for students dragged out of it.
require "view_component/base"
class GroupRowComponent < ViewComponent::Base
  with_collection_parameter :registerable

  attr_reader :registerable, :item

  delegate :capacity, to: :registerable

  def initialize(registerable:, item: nil)
    super()
    @registerable = registerable
    @item = item
  end

  def render?
    registerable.present?
  end

  def dom_target
    item || registerable
  end

  def row_classes
    [
      "group-row",
      ("group-row--self-enrollment" if !item && sm_active?),
      ("group-row--without-enrollment" if cohort_without_enrollment?)
    ].compact.join(" ")
  end

  def type_text
    helpers.roster_type_text(registerable, item: item)
  end

  def roster_key
    "#{registerable.class.name}-#{registerable.id}"
  end

  def panel_path
    if item&.registration_campaign&.open?
      helpers.roster_registration_campaign_item_path(
        item.registration_campaign, item,
        source: :panel, format: :turbo_stream
      )
    else
      helpers.roster_panel_path(registerable)
    end
  end

  def edit_path
    helpers.roster_edit_group_path(registerable)
  end

  def delete_path
    if item
      helpers.with_registerable_registration_campaign_item_path(
        item.registration_campaign, item
      )
    else
      helpers.roster_delete_group_path(registerable)
    end
  end

  def remove_path
    return unless item

    helpers.registration_campaign_item_path(item.registration_campaign, item)
  end

  def add_member_path
    helpers.roster_add_member_path(registerable)
  end

  def delete_disabled?
    delete_blocker_messages.any?
  end

  def delete_disabled_title
    delete_blocker_messages.to_sentence
  end

  # A blocked button keeps its place in the tab order, so its name has to
  # carry the reason - the tooltip on the wrapper is mouse-only.
  def delete_disabled_label
    "#{delete_label}. #{delete_disabled_title}"
  end

  def remove_disabled?
    remove_blocker_message.present?
  end

  def remove_disabled_title
    remove_blocker_message
  end

  def remove_disabled_label
    "#{remove_label}. #{remove_disabled_title}"
  end

  def delete_data
    {
      turbo_method: :delete,
      turbo_confirm: delete_confirmation,
      bs_toggle: "tooltip"
    }
  end

  def delete_confirmation
    return t("registration.item.confirm_delete_group") if item

    total = campaign_registrations.values.sum
    return t("roster.actions.confirm_delete_group") if total.zero?

    t("roster.actions.confirm_delete_group_with_registrations",
      total: t("roster.actions.confirm_delete_group_total_count", count: total),
      confirmed: t("roster.actions.confirm_delete_group_confirmed_count",
                   count: campaign_registrations["confirmed"].to_i))
  end

  # Registrations per status. A completed campaign leaves them on the group,
  # and deleting the group deletes them, so the confirmation counts them.
  def campaign_registrations
    @campaign_registrations ||=
      Registration::UserRegistration
      .where(registration_item_id: registerable.registration_items.select(:id))
      .group(:status).count
  end

  def remove_data
    {
      turbo_method: :delete,
      turbo_confirm: t("registration.item.confirm_remove_from_campaign"),
      bs_toggle: "tooltip"
    }
  end

  def delete_title
    if item
      t("registration.item.actions.delete_group")
    else
      t("roster.tooltips.delete")
    end
  end

  def remove_title
    t("registration.item.actions.remove_from_campaign")
  end

  # Every row carries the same three buttons, so their names say which group
  # they act on.
  def edit_label
    "#{t("roster.tooltips.edit_settings")}: #{registerable.title}"
  end

  def delete_label
    "#{delete_title}: #{registerable.title}"
  end

  def remove_label
    "#{remove_title}: #{registerable.title}"
  end

  # The item recomputes on every call, and the row needs the answer thrice.
  def remove_blocker_message
    return @remove_blocker_message if defined?(@remove_blocker_message)

    @remove_blocker_message = item&.removal_blocker_message
  end

  # Two hurdles: the item may leave the campaign, and the group itself carries
  # nothing worth keeping.
  def delete_blocker_messages
    @delete_blocker_messages ||=
      if item
        Array(remove_blocker_message) +
          registerable.destruction_blocker_messages(
            registerable.destruction_blockers_outside_campaign
          )
      else
        registerable.destruction_blocker_messages
      end
  end

  # What the number in the row counts: the first choices of an open
  # preference-based campaign, the confirmed registrations of a first come,
  # first served one, and the roster otherwise. The first two are not a roster
  # yet, and a preference is demand, not a seat.
  def count_kind
    return :members unless item
    return :confirmed if item.registration_campaign.first_come_first_served?

    :first_choices
  end

  def count
    @count ||= case count_kind
               when :first_choices then item.first_choice_count
               when :confirmed then item.confirmed_registrations_count
               else registerable.roster_entries.count
    end
  end

  def count_text
    if count_kind == :first_choices
      seats = if capacity
        I18n.t("roster.group_row.seats", count: capacity)
      else
        I18n.t("roster.group_row.no_limit")
      end
      return "#{I18n.t("roster.group_row.first_choices", count: count)} · #{seats}"
    end

    return I18n.t("roster.group_row.#{count_kind}_unlimited", count: count) if capacity.nil?

    I18n.t("roster.group_row.#{count_kind}", count: count, capacity: capacity)
  end

  # [kind, text] for the line under the number, or nil.
  def count_state
    if count_kind == :first_choices
      return if capacity.nil? || count <= capacity

      return [:demand, I18n.t("roster.group_row.demand_exceeds_seats")]
    end

    return [:plain, I18n.t("roster.group_row.no_limit")] if capacity.nil?
    if count > capacity
      return [:over, I18n.t("roster.group_row.over_capacity", count: count - capacity)]
    end
    return [:full, I18n.t("roster.group_row.full")] if count == capacity

    [:plain, I18n.t("roster.group_row.seats_available", count: capacity - count)]
  end

  def badge_class(kind)
    "group-row__badge--#{kind}"
  end

  # Demand has no bar: three and thirty first choices would fill it alike,
  # and a full bar reads as filled seats.
  def bar?
    count_kind != :first_choices && capacity.present?
  end

  def bar_percent
    return 100 if capacity.zero?

    [count * 100 / capacity, 100].min
  end

  def over_capacity?
    capacity.present? && count > capacity
  end

  def tutors_text
    helpers.roster_tutors_text(registerable)
  end

  def people_label
    registerable.is_a?(Talk) ? t("basics.speakers") : t("basics.tutors")
  end

  def location_text
    registerable.try(:location)
  end

  # Talks carry scheduled dates; other rosterables do not respond to :dates.
  def date_text
    return unless registerable.respond_to?(:dates)

    Array(registerable.dates)
      .filter_map { |d| d&.strftime("%b %d %Y") }
      .join(", ")
      .presence
  end

  def sm_mode
    registerable.try(:self_materialization_mode) || "disabled"
  end

  def sm_active?
    sm_mode != "disabled"
  end

  def cohort_without_enrollment?
    registerable.is_a?(Cohort) && !registerable.propagate_to_lecture?
  end

  def show_self_enrollment_dropdown?
    !item &&
      registerable.respond_to?(:skip_campaigns) &&
      !registerable.locked?
  end

  def sm_icon_class
    sm_icon_for(sm_mode)
  end

  def sm_icon_for(mode)
    case mode
    when "add_only"       then "bi-box-arrow-in-right"
    when "remove_only"    then "bi-box-arrow-right"
    when "add_and_remove" then "bi-arrow-left-right"
    else "bi-person-slash"
    end
  end

  def sm_button_class
    sm_active? ? "text-success" : "text-muted"
  end

  # The disabled mode's name already says what it is about; the others need
  # the label in front of them.
  def sm_text
    mode_label = t("roster.self_materialization.modes.#{sm_mode}",
                   default: sm_mode.humanize)
    return mode_label unless sm_active?

    "#{t("roster.self_materialization.label", default: "Self-Enrollment")}: #{mode_label}"
  end

  def sm_modes
    registerable.class.self_materialization_modes.keys
  end

  def sm_update_path(mode)
    helpers.roster_update_self_materialization_path(
      registerable, mode: mode
    )
  end

  def bulk_sm_path
    helpers.roster_bulk_sm_path(registerable, mode: sm_mode)
  end

  def bulk_sm_confirm
    mode_label = t(sm_mode,
                   scope: "roster.self_materialization.modes",
                   default: sm_mode.titleize)
    t("roster.self_materialization.confirm_bulk_update",
      mode: mode_label)
  end
end
