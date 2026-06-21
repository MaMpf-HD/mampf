module EligibilityHelper
  POLICY_CONFIG_UNAVAILABLE = "No configuration available".freeze

  def eligibility_failure_message(policy, user: nil, context: :registration)
    key, options = eligibility_failure_translation(policy, user: user,
                                                           context: context)

    t(key, **options)
  end

  private

    def eligibility_failure_translation(policy, user: nil, context: :registration)
      case policy[:kind].to_s
      when "institutional_email"
        eligibility_failure_translation_for_institutional_email(
          policy,
          user: user,
          context: context
        )
      when "prerequisite_campaign"
        eligibility_failure_translation_for_prerequisite_campaign(policy)
      when "student_performance"
        [
          "registration.user_registration.eligibility_failures.student_performance_failed",
          { status: policy_config_info(policy) }
        ]
      else
        [
          "registration.user_registration.eligibility_failures.generic_html",
          { requirement: eligibility_requirement_label(policy) }
        ]
      end
    end

    def eligibility_failure_translation_for_institutional_email(policy,
                                                                context:, user: nil)
      case policy.dig(:outcome, :code).to_s
      when "institutional_email_mismatch"
        institutional_email_mismatch_translation(policy, user: user,
                                                         context: context)
      when "configuration_error"
        [
          "registration.user_registration.eligibility_failures." \
          "institutional_email_configuration_error",
          {}
        ]
      else
        generic_eligibility_failure_translation(policy)
      end
    end

    def eligibility_failure_translation_for_prerequisite_campaign(policy)
      case policy.dig(:outcome, :code).to_s
      when "prerequisite_not_met"
        [
          "registration.user_registration.eligibility_failures.prerequisite_not_met",
          { campaign: prerequisite_campaign_label(policy) }
        ]
      when "prerequisite_campaign_not_found"
        [
          "registration.user_registration.eligibility_failures.prerequisite_campaign_not_found",
          { campaign: prerequisite_campaign_label(policy) }
        ]
      when "configuration_error"
        [
          "registration.user_registration.eligibility_failures.prerequisite_configuration_error",
          {}
        ]
      else
        generic_eligibility_failure_translation(policy)
      end
    end

    def generic_eligibility_failure_translation(policy)
      [
        "registration.user_registration.eligibility_failures.generic_html",
        { requirement: eligibility_requirement_label(policy) }
      ]
    end

    def institutional_email_mismatch_translation(policy, user: nil,
                                                 context: :registration)
      case context
      when :finalization_rejection
        [
          "registration.user_registration.eligibility_failures." \
          "institutional_email_finalization_rejection",
          { domains: policy_config_info(policy) }
        ]
      else
        [
          "registration.user_registration.eligibility_failures." \
          "institutional_email_mismatch_html",
          {
            current_domain: user_email_domain(user),
            domains: policy_config_info(policy),
            profile: link_to(t("navbar.profile"), edit_profile_path,
                             class: "fw-semibold", target: "_top")
          }
        ]
      end
    end

    def policy_config_info(policy)
      case policy[:kind].to_s
      when "student_performance"
        policy.dig(:config, "certification_status").to_s.capitalize
      when "institutional_email"
        Array(policy.dig(:config, "allowed_domains")).join(", ")
      when "prerequisite_campaign"
        policy.dig(:config, "prerequisite_campaign")
      else
        POLICY_CONFIG_UNAVAILABLE
      end
    end

    def user_email_domain(user)
      domain = user&.email.to_s.strip.downcase.split("@", 2).last
      return domain if domain.present?

      I18n.t("registration.user_registration.eligibility_failures.current_domain_unknown")
    end

    def prerequisite_campaign_label(policy)
      campaign = policy_config_info(policy)
      return eligibility_requirement_label(policy) if campaign == POLICY_CONFIG_UNAVAILABLE

      campaign
    end

    def eligibility_requirement_label(policy)
      I18n.t("registration.policy.kinds.#{policy[:kind]}",
             default: policy[:kind].to_s.humanize).downcase
    end
end
