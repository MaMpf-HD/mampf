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
    # lecture_performance -> config: { certification_status: :pending }
    # institutional_email	-> config:	{ allowed_domains: ["uni-heidelberg.de "] }
    # prerequisite_campaign	-> config:	{ prerequisite_campaign_id: 42 }
    #
    # Notice config here is JSON object, so keys are string types
    # policy here is also hash, not policy object
    def get_policy_config_info(policy)
      case policy[:kind]
      when "lecture_performance"
        cert_status = policy[:config]["certification_status"]
        cert_status.capitalize
      when "institutional_email"
        domains = Array(policy[:config]["allowed_domains"])
        domains.join(", ")
      when "prerequisite_campaign"
        policy[:config]["prerequisite_campaign_id"]
      else
        "No configuration available"
      end
    end

    def get_details_render_type_policy_kind(kind)
      case kind
      when "prerequisite_campaign"
        "link"
      else
        "text"
      end
    end

    def single_mode?(registerable_type)
      regist_type = registerable_type.downcase
      ["lecture"].include?(regist_type)
    end

    # TODO: in the future
    # when tutorial field change (eg: tutorial.title), also adjust this
    TABLE_CONFIG = {
      "Tutorial" => [
        { header: I18n.t("registration.item.types.tutorial"),
          cell_class: "text-start fw-medium",
          field: ->(item) { item.registerable.title } },
        # { header: I18n.t("basics.time"),
        #   field: lambda { item.time } },
        { header: I18n.t("basics.tutor"),
          cell_class: "text-start fw-semibold",
          field: ->(item) { item.registerable.tutor_names } }
      ],
      "Talk" => [
        { header: I18n.t("registration.item.types.talk"),
          cell_class: "text-start fw-medium",
          field: ->(item) { item.registerable.title } },
        { header: I18n.t("basics.position"),
          cell_class: "text-end",
          field: ->(item) { item.registerable.position } },
        { header: I18n.t("basics.date"),
          field: lambda { |item|
            item.registerable.dates&.map do |d|
              format_date(d)
            end&.join(", ")
          } }
      ],
      "Cohort" => [
        { header: I18n.t("registration.item.types.cohort"),
          cell_class: "text-start fw-medium",
          field: ->(item) { item.registerable.title } },
        { header: I18n.t("basics.description"),
          cell_class: "text-center",
          field: ->(item) { item.registerable.description } }
      ]
    }.freeze

    def format_date(time)
      return "" if time.nil?

      time.strftime("%b %d, %H:%M")
    end
    module_function :format_date

    OUTCOME_MAP = {
      true => { text: I18n.t("basics.passed"),
                badge_class: "badge rounded-pill w-auto text-bg-success" },
      false => { text: I18n.t("basics.failed"),
                 badge_class: "badge rounded-pill w-auto text-bg-danger" }
    }.freeze

    def get_outcome_info(outcome)
      OUTCOME_MAP[outcome[:pass]]
    end

    def eligibility_badge(pass)
      if pass
        content_tag(:span, I18n.t("registration.eligible"),
                    class: "badge rounded-pill w-auto text-bg-success")
      else
        content_tag(:span, I18n.t("registration.not_eligible"),
                    class: "badge rounded-pill w-auto text-bg-warning")
      end
    end

    def confirm_status_badge(status)
      case status
      when "confirmed"
        content_tag(:span, I18n.t("basics.confirmed"),
                    class: "badge rounded-pill w-auto text-bg-success")
      when "pending"
        content_tag(:span, I18n.t("basics.pending"),
                    class: "badge rounded-pill w-auto text-bg-warning")
      when "rejected"
        content_tag(:span, I18n.t("basics.rejected"),
                    class: "badge rounded-pill w-auto text-bg-danger")
      when "dismissed"
        content_tag(:span, I18n.t("basics.dismissed"),
                    class: "badge rounded-pill w-auto text-bg-danger")
      else
        content_tag(:span, "")
      end
    end

    def sum_of_nullable(values)
      return nil if values.any?(&:nil?)

      values.sum
    end

    def nil_or_positive_integer?(value)
      value.nil? || (value.is_a?(Integer) && value.positive?)
    end

    def nullable_capacity_display(capacity)
      capacity.nil? ? "\u221E" : capacity.to_s
    end

    def status_campaign_style(status)
      case status
      when "open", "completed"
        "bg-success-subtle text-success"
      when "closed", "processing"
        "bg-secondary-subtle text-secondary"
      else
        "bg-info-subtle text-info"
      end
    end
  end
end
