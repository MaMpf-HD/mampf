module UserRegistrationsHelper
  include GtileIconHelper

  TABLE_CONFIG = {
    "Tutorial" => [
      { header: "basics.tutor",
        cell_class: "text-start fw-semibold",
        icon: "person",
        field: ->(rosterable) { rosterable.tutor_names } },
      { header: "basics.location",
        cell_class: "text-start fw-semibold",
        icon: "location",
        field: ->(rosterable) { rosterable.location } }
    ],
    "Talk" => [
      # Position is shown in the tile header ("Talk N", see
      # Registration::ItemsHelper#item_display_type). The description is
      # intentionally omitted: it is a rich-text abstract, gated by
      # `display_description` elsewhere, and does not belong in the compact
      # registration tile.
      { header: "basics.date",
        icon: "event",
        field: lambda { |rosterable|
          rosterable.dates&.map do |d|
            d.nil? ? "" : d.strftime("%b %d %Y")
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

  def format_date(time)
    return "" if time.nil?

    l(time, format: :student_registration)
  end

  def student_registration_campaign_title(campaign)
    campaign.student_facing_title
  end

  def student_registration_instruction(campaign, items = [])
    key = if campaign.first_come_first_served?
      "first_come_first_served_instruction"
    else
      "preference_instruction"
    end

    return t("registration.user_registration.#{key}") if campaign.first_come_first_served?

    t("registration.user_registration.#{key}",
      count: preference_rank_count(items))
  end

  def student_visible_campaign?(campaign)
    campaign.open? || campaign.closed? || campaign.processing?
  end

  def student_registration_readonly?(campaign)
    student_visible_campaign?(campaign) && !campaign.open_for_registrations?
  end

  def sorted_student_visible_campaigns(campaigns_details)
    visible_campaigns = campaigns_details.select do |campaign_details|
      student_visible_campaign?(campaign_details.campaign)
    end

    readonly_campaigns, open_campaigns = visible_campaigns.partition do |campaign_details|
      student_registration_readonly?(campaign_details.campaign)
    end

    readonly_campaigns.sort_by do |campaign_details|
      -student_registration_readonly_changed_at(campaign_details.campaign).to_i
    end + open_campaigns
  end

  def sorted_student_registration_items(campaign, items, user)
    items.sort_by do |item|
      [student_registration_item_priority(campaign, item, user),
       item_display_type(item).to_s,
       item.registerable.title.to_s]
    end
  end

  def preference_rank_for(item, item_preferences)
    item_preferences.find { |pref| pref.item.id == item.id }&.rank
  end

  def preference_rank_count(items)
    [Array(items).size, UserRegistrations::PreferencesHandler::MAX_PREFERENCES].min
  end

  def preference_ranks_for(items)
    1..preference_rank_count(items)
  end

  def preference_rank_button_tooltip(rank)
    rank_label = t("registration.user_registration.preference_rank_options.#{rank}")
    t("registration.user_registration.actions.rank_option_tooltip",
      rank: rank_label)
  end

  def item_capacity_row(item)
    "#{item.item_capacity_used} / #{nullable_capacity_display(item.capacity)}"
  end

  def item_tile_metadata_rows(item)
    metadata_rows_for(item.registerable_type, item.registerable)
  end

  def self_rosterable_display_type(rosterable)
    case rosterable.class.name
    when "Tutorial"
      t("registration.item.types.tutorial")
    when "Talk"
      "#{t("registration.item.types.talk")} #{rosterable.position}"
    when "Cohort"
      t("registration.item.types.other_group")
    end
  end

  def self_rosterable_tile_metadata_rows(rosterable)
    metadata_rows_for(rosterable.class.name, rosterable)
  end

  def freely_registerable?(group_type)
    group_type == "Cohort"
  end

  def nullable_capacity_display(capacity)
    capacity.nil? ? "\u221E" : capacity.to_s
  end

  def registration_blocked_by_unremovable_assignment?(lecture)
    return false if lecture.blank?
    return @registration_blocked_by_unremovable_assignment \
      unless @registration_blocked_by_unremovable_assignment.nil?

    @registration_blocked_by_unremovable_assignment =
      Rosters::SelfRosterAvailability.new(lecture, current_user)
                                     .blocked_by_unremovable_assignment?
  end

  def registration_blocked_tooltip
    t("registration.user_registration.blocked_tooltip")
  end

  def registration_blocked_tile_locals(blocked, tile_variant_class: "tutorial-gtile--campaign")
    {
      tile_tooltip_text: (registration_blocked_tooltip if blocked),
      tile_variant_class: class_names(
        tile_variant_class,
        "tutorial-gtile--blocked": blocked
      )
    }
  end

  def registration_blocked_action
    render partial: "user_registrations/registration_blocked_action"
  end

  private

    def student_registration_readonly_changed_at(campaign)
      return campaign.last_allocation_calculated_at || campaign.updated_at if campaign.processing?

      campaign.updated_at
    end

    def student_registration_item_priority(campaign, item, user)
      return 0 if item.user_registered?(user)
      return 1 if student_registration_item_available?(campaign, item, user)
      return 3 unless item.still_has_capacity?

      2
    end

    def student_registration_item_available?(campaign, item, user)
      return false unless campaign.open_for_registrations?
      return false unless item.still_has_capacity?
      return true if freely_registerable?(item.registerable_type)

      !campaign.user_registration_confirmed_for_group_type?(
        user,
        item.registerable_type
      )
    end

    def metadata_label_for(col)
      t(col[:header])
    end

    # Rows with a blank value are dropped so we never render a lone icon with
    # no data next to it (e.g. a talk without a description or dates).
    def metadata_rows_for(type, rosterable)
      TABLE_CONFIG[type].filter_map do |col|
        value = col[:field].call(rosterable)
        next if value.blank?

        {
          label: metadata_label_for(col),
          value: value,
          icon: gtile_icon_for(col[:icon])
        }
      end
    end
end
