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
    ],
    "Exam" => [
      { header: "basics.date",
        icon: "event",
        field: lambda { |rosterable|
          rosterable.date && I18n.l(rosterable.date,
                                    format: :student_registration)
        } },
      { header: "basics.location",
        cell_class: "text-start fw-semibold",
        icon: "location",
        field: ->(rosterable) { rosterable.location } }
    ]
  }.freeze

  OPTIONS_SHOWN_AT_FIRST = 8

  def option_seats_text(capacity, used)
    return t("registration.user_registration.options.unlimited") if capacity.nil?

    free = capacity - used
    return t("registration.user_registration.options.full") unless free.positive?

    t("registration.user_registration.options.free", free: free, capacity: capacity)
  end

  def lecture_home_badge_class(kind)
    "lecture-home-badge lecture-home-badge--#{kind}"
  end

  def format_date(time)
    return "" if time.nil?

    l(time, format: :student_registration)
  end

  def student_registration_campaign_title(campaign)
    campaign.student_facing_title
  end

  def student_registration_instruction(campaign, items = [])
    key = if campaign.exam_campaign?
      "first_come_first_served_instruction_exam"
    elsif campaign.first_come_first_served?
      "first_come_first_served_instruction"
    else
      "preference_instruction"
    end

    return t("registration.user_registration.#{key}") if campaign.first_come_first_served?

    t("registration.user_registration.#{key}",
      count: preference_rank_count(items))
  end

  def registration_needs_action?(details)
    campaign = details.campaign
    return false if Array(details.own_registrations).any? do |registration|
      registration.confirmed? || (registration.pending? && registration.preference_rank)
    end
    return false unless Array(details.eligibility).all? { |policy| policy.dig(:outcome, :pass) }
    return false if registration_campaign_blocked?(campaign, details.items)

    campaign.preference_based? || details.items.any?(&:still_has_capacity?)
  end

  def student_visible_campaign?(campaign)
    campaign.open? || campaign.closed? || campaign.processing?
  end

  def student_registration_readonly?(campaign)
    student_visible_campaign?(campaign) && !campaign.open_for_registrations?
  end

  # Puts the student's own registration first and keeps the rest in the order
  # of the program, full or not: "Talk N" carries the talk's position.
  def sorted_student_registration_items(items, user)
    registered_ids = Registration::UserRegistration.confirmed
                                                   .where(user_id: user.id,
                                                          registration_item_id: items.map(&:id))
                                                   .pluck(:registration_item_id)

    items.natural_sort_by do |item|
      own = item.id.in?(registered_ids) ? 0 : 1
      [own, item_display_type(item), item.registerable.title].join(" | ")
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

  def registration_blocked_by_unremovable_assignment?(lecture)
    return false if lecture.blank?
    return @registration_blocked_by_unremovable_assignment \
      unless @registration_blocked_by_unremovable_assignment.nil?

    @registration_blocked_by_unremovable_assignment =
      Rosters::SelfRosterAvailability.new(lecture, current_user)
                                     .blocked_by_unremovable_assignment?
  end

  # Whether the student may not register for this item: it is a tutorial and
  # they sit in one they are not allowed to leave. The edit services refuse
  # the same registration.
  def registration_item_blocked?(item, lecture)
    item.registerable.roster_exclusive_within_lecture? &&
      registration_blocked_by_unremovable_assignment?(lecture)
  end

  def registration_campaign_blocked?(campaign, items)
    items = Array(items)
    items.any? && items.all? { |item| registration_item_blocked?(item, campaign.campaignable) }
  end

  def registration_blocked_tooltip
    t("registration.user_registration.blocked_tooltip")
  end

  private

    def metadata_label_for(col)
      t(col[:header])
    end

    # Rows with a blank value are dropped so we never render a lone icon with
    # no data next to it (e.g. a talk without a description or dates).
    def metadata_rows_for(type, rosterable)
      TABLE_CONFIG.fetch(type).filter_map do |col|
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
