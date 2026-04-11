# This component renders a tile for a roster group (tutorial, talk or cohort).
require "view_component/base"
class GroupTileComponent < ViewComponent::Base
  with_collection_parameter :registerable

  attr_reader :registerable, :item

  def initialize(registerable:, item: nil, lecture: nil)
    super()
    @registerable = registerable
    @item = item
    @lecture = lecture
  end

  def render?
    registerable.present?
  end

  def dom_target
    item || registerable
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
      helpers.registration_campaign_item_path(
        item.registration_campaign, item
      )
    else
      helpers.roster_delete_group_path(registerable)
    end
  end

  def add_member_path
    helpers.roster_add_member_path(registerable)
  end

  def delete_disabled?
    if item
      !item.registration_campaign.draft?
    else
      !registerable.destructible?
    end
  end

  def delete_disabled_title
    if item
      t("registration.item.cannot_destroy")
    elsif registerable.in_campaign?
      t("roster.errors.cannot_delete_in_campaign")
    else
      t("roster.errors.cannot_delete_not_empty")
    end
  end

  def delete_data
    confirm_key = if item
      "registration.item.confirm_remove"
    else
      "roster.actions.confirm_delete_group"
    end
    {
      turbo_method: :delete,
      turbo_confirm: t(confirm_key),
      bs_toggle: "tooltip"
    }
  end

  def delete_title
    if item
      t("registration.item.actions.remove_from_campaign")
    else
      t("roster.tooltips.delete")
    end
  end

  def registration_count
    return unless item

    campaign = item.registration_campaign
    if campaign.first_come_first_served?
      item.user_registrations.count
    else
      item.first_choice_count
    end
  end

  def tutors_text
    helpers.roster_tutors_text(registerable)
  end

  def location_text
    registerable.try(:location)
  end

  def type_text
    helpers.roster_type_text(registerable, item: item)
  end

  def sm_mode
    registerable.try(:self_materialization_mode) || "disabled"
  end

  def sm_active?
    sm_mode != "disabled"
  end

  def gtile_type_class
    if item
      "tutorial-gtile--campaign"
    elsif sm_active?
      "tutorial-gtile--self-enrollment"
    else
      "tutorial-gtile--free"
    end
  end

  def top_bar_class
    if item
      "tutorial-gtile-top-bar--campaign"
    elsif sm_active?
      "tutorial-gtile-top-bar--self-enrollment"
    else
      "tutorial-gtile-top-bar--free"
    end
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

  def sm_tooltip
    label = t("roster.self_materialization.label",
              default: "Self-Enrollment")
    mode_label = t("roster.self_materialization.modes.#{sm_mode}",
                   default: sm_mode.humanize)
    "#{label}: #{mode_label}"
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
