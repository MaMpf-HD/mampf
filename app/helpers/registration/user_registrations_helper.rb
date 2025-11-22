module Registration
  module UserRegistrationsHelper
    MODE_MAP = {
      -1 => { mode_name: "Unknown", abbr: "UNK" },
      0 => { mode_name: "First-come, first-served", abbr: "FCFS" },
      1 => { mode_name: "Preference Based", abbr: "PB" }
    }
    def get_mode_info(mode)
      if (mode == 1) || (mode == 0)
        MODE_MAP[mode]
      else
        MODE_MAP[-1]
      end
    end

    # Examples of policy config:
    # lecture_performance -> config: { certification_status: :pending }
    # institutional_email	-> config:	{ domain: "gmail.com", allowed: ["uni.edu"] }
    # prerequisite_campaign	-> config:	{ prerequisite_campaign_id: 42 }
    # Notice config here is JSON object, so keys are string types
    def get_policy_config_info(policy)
      case policy.kind.to_s
      when "lecture_performance"
        cert_status = policy.config["certification_status"]
        cert_status.capitalize
      when "institutional_email"
        domains = Array(policy.config["domain"])
        domains.join(", ")
      when "prerequisite_campaign"
        {
          id: policy.config["prerequisite_campaign_id"],
          info: policy.config["prerequisite_campaign_info"]
        } 
      else
        "No configuration available"
      end
    end

    def get_details_render_type_policy(policy)
      case policy.kind.to_s
      when "prerequisite_campaign"
        "link"
      else
        "text"
      end
    end
  end
end
