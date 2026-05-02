module Registration
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

    # Examples of policy config:
    # student_performance -> config: { certification_status: :pending }
    # institutional_email	-> config:	{ allowed_domains: ["uni-heidelberg.de "] }
    # prerequisite_campaign	-> config:	{ prerequisite_campaign: name }
    #
    # Notice config here is JSON object, so keys are string types
    # policy here is also hash, not policy object
    def get_policy_config_info(policy)
      case policy[:kind]
      when "student_performance"
        cert_status = policy[:config]["certification_status"]
        cert_status.capitalize
      when "institutional_email"
        domains = Array(policy[:config]["allowed_domains"])
        domains.join(", ")
      when "prerequisite_campaign"
        policy[:config]["prerequisite_campaign"]
      else
        "No configuration available"
      end
    end

    def get_details_render_type_policy_kind(kind)
      return "badge" if kind == "student_performance"

      "text"
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

      time.strftime("%b %d, %H:%M")
    end

    OUTCOME_MAP = {
      true => { text: "basics.passed",
                badge_class: "badge rounded-pill w-auto text-bg-success" },
      false => { text: "basics.failed",
                 badge_class: "badge rounded-pill w-auto text-bg-danger" }
    }.freeze

    def get_outcome_info(outcome)
      OUTCOME_MAP[outcome[:pass]]
    end

    def eligibility_badge(pass)
      if pass
        content_tag(:span, I18n.t("registration.user_registration.eligible"),
                    class: "badge rounded-pill w-auto text-bg-success")
      else
        content_tag(:span, I18n.t("registration.user_registration.not_eligible"),
                    class: "badge rounded-pill w-auto text-bg-warning")
      end
    end

    def eligible_for_registration?(eligibility)
      eligibility.all? { |policy| policy[:outcome][:pass] }
    end

    def student_registration_campaign_title(campaign)
      campaign.description.presence ||
        t("registration.user_registration.campaign_main")
    end

    def student_registration_instruction(campaign)
      key = if campaign.first_come_first_served?
        "fcfs_instruction"
      else
        "preference_instruction"
      end

      t("registration.user_registration.#{key}")
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

    def preference_rank_button_tooltip(rank)
      rank_label = t("registration.user_registration.preference_rank_options.#{rank}")
      t("registration.user_registration.actions.rank_option_tooltip",
        rank: rank_label)
    end

    def item_capacity_row(item)
      "#{item.item_capacity_used} / #{nullable_capacity_display(item.capacity)}"
    end

    def confirm_status_badge(status)
      case status
      when "confirmed"
        content_tag(:span, I18n.t("basics.confirmed"),
                    class: "badge fw-medium small w-auto text-bg-success")
      when "pending"
        content_tag(:span, I18n.t("basics.pending"),
                    class: "badge fw-medium small w-auto text-bg-warning")
      when "rejected"
        content_tag(:span, I18n.t("basics.rejected"),
                    class: "badge fw-medium small w-auto text-bg-danger")
      when "dismissed"
        content_tag(:span, I18n.t("basics.dismissed"),
                    class: "badge fw-medium small w-auto text-bg-danger")
      else
        content_tag(:span, "")
      end
    end

    def sum_of_nullable(values)
      return nil if values.any?(&:nil?)

      values.sum
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

    def freely_registerable?(group_type)
      group_type == "Cohort"
    end

    def nullable_capacity_display(capacity)
      capacity.nil? ? "\u221E" : capacity.to_s
    end

    private

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
  end
end
