module UserRegistrationsHelper
  MODE_MAP = {
    -1 => { mode_name: "Unknown", abbr: "UNK",
            badge_class: "bg-grey-lighten-4 text-grey" },
    0 => { mode_name: "First-come, first-served", abbr: "FCFS",
           badge_class: "bg-light-blue-lighten-4 text-darkblue" },
    1 => { mode_name: "Preference Based", abbr: "PB",
           badge_class: "bg-mdb-color-lighten-3 text-white" }
  }.freeze
  def get_mode_info(mode)
    MODE_MAP.fetch(mode, MODE_MAP[-1])
  end

  def single_mode?(registerable_type)
    regist_type = registerable_type.downcase
    ["lecture"].include?(regist_type)
  end

  TABLE_CONFIG = {
    "Tutorial" => [
      { header: "basics.tutor",
        cell_class: "text-start fw-semibold",
        icon: "person",
        field: ->(item) { item.registerable.tutor_names } },
      { header: "basics.location",
        cell_class: "text-start fw-semibold",
        icon: "location",
        field: ->(item) { item.registerable.location } }
    ],
    "Talk" => [
      { header: "basics.position",
        cell_class: "text-end",
        icon: "looks_one",
        field: ->(item) { item.registerable.position } },
      { header: "basics.description",
        icon: "description",
        cell_class: "text-center",
        field: ->(item) { item.registerable.description } },
      { header: "basics.date",
        icon: "event",
        field: lambda { |item|
          item.registerable.dates&.map do |d|
            d.nil? ? "" : d.strftime("%b %d %Y")
          end&.join(", ")
        } }
    ],
    "Cohort" => [
      { header: "basics.description",
        icon: "description",
        cell_class: "text-center",
        field: ->(item) { item.registerable.description } }
    ]
  }.freeze

  def format_date(time)
    return "" if time.nil?

    l(time, format: :student_registration)
  end

  def student_registration_campaign_title(campaign)
    description = campaign.description.to_s.strip
    return description if description.present?

    t("registration.user_registration.campaign_main")
  end

  def student_registration_instruction(campaign, items = [])
    key = if campaign.first_come_first_served?
      "fcfs_instruction"
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
    TABLE_CONFIG[item.registerable_type].map do |col|
      {
        label: metadata_label_for(col),
        value: col[:field].call(item),
        icon: gtile_icon_for(col[:icon])
      }
    end
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
    TABLE_CONFIG[rosterable.class.name].map do |col|
      {
        label: metadata_label_for(col),
        value: self_rosterable_metadata_value(col, rosterable),
        icon: gtile_icon_for(col[:icon])
      }
    end
  end

  def freely_registerable?(group_type)
    group_type == "Cohort"
  end

  def nullable_capacity_display(capacity)
    capacity.nil? ? "\u221E" : capacity.to_s
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

    def gtile_icon_for(icon_name)
      case icon_name
      when "person"   then "bi-person"
      when "location" then "bi-geo-alt"
      end
    end

    def metadata_label_for(col)
      return if col[:header] == "basics.description"

      t(col[:header])
    end

    def self_rosterable_metadata_value(col, rosterable)
      case col[:header]
      when "basics.tutor"
        rosterable.tutor_names
      when "basics.location"
        rosterable.location
      when "basics.position"
        rosterable.position
      when "basics.description"
        rosterable.description
      when "basics.date"
        rosterable.dates&.map do |date|
          date.nil? ? "" : date.strftime("%b %d %Y")
        end&.join(", ")
      end
    end
end
