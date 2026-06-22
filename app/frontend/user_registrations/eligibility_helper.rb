module EligibilityHelper
  POLICY_CONFIG_UNAVAILABLE = "No configuration available".freeze
  POLICY_STATUS_NEEDS_CLARIFICATION_CODES = [
    "configuration_error",
    "prerequisite_campaign_not_found"
  ].freeze

  def eligibility_failure_message(policy, user: nil, context: :registration)
    key, options = eligibility_failure_translation(policy, user: user,
                                                           context: context)

    t(key, **options)
  end

  def eligibility_policy_summary(policy)
    case policy[:kind].to_s
    when "institutional_email"
      t("registration.user_registration.policy_overview.policies." \
        "institutional_email",
        domains: policy_config_info(policy))
    when "prerequisite_campaign"
      t("registration.user_registration.policy_overview.policies." \
        "prerequisite_campaign",
        campaign: prerequisite_campaign_label(policy))
    when "student_performance"
      t("registration.user_registration.policy_overview.policies." \
        "student_performance",
        status: policy_config_info(policy))
    else
      t("registration.user_registration.policy_overview.policies.generic",
        requirement: eligibility_requirement_label(policy))
    end
  end

  def eligibility_policy_status_label(policy)
    t("registration.user_registration.policy_overview.status." \
      "#{eligibility_policy_status_key(policy)}")
  end

  def eligibility_policy_status_badge_class(policy)
    case eligibility_policy_status_key(policy)
    when "fulfilled"
      "text-bg-success"
    when "needs_clarification"
      "text-bg-warning"
    else
      "text-bg-danger"
    end
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
        eligibility_failure_translation_for_prerequisite_campaign(
          policy,
          context: context
        )
      when "student_performance"
        eligibility_failure_translation_for_student_performance(
          policy,
          context: context
        )
      else
        generic_eligibility_failure_translation(policy, context: context)
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
        generic_eligibility_failure_translation(policy, context: context)
      end
    end

    def eligibility_failure_translation_for_prerequisite_campaign(policy,
                                                                  context: :registration)
      case policy.dig(:outcome, :code).to_s
      when "prerequisite_not_met"
        [
          prerequisite_not_met_translation_key(context),
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
        generic_eligibility_failure_translation(policy, context: context)
      end
    end

    def eligibility_failure_translation_for_student_performance(policy,
                                                                context: :registration)
      [
        student_performance_translation_key(context),
        { status: policy_config_info(policy) }
      ]
    end

    def generic_eligibility_failure_translation(policy, context: :registration)
      [
        generic_translation_key(context),
        { requirement: eligibility_requirement_label(policy) }
      ]
    end

    def institutional_email_mismatch_translation(policy, user: nil,
                                                 context: :registration)
      case context
      when :finalization_warning
        [
          "registration.user_registration.eligibility_failures." \
          "institutional_email_finalization_warning_html",
          {
            current_domain: user_email_domain(user),
            domains: policy_config_info(policy),
            profile: link_to(t("navbar.profile"), edit_profile_path,
                             class: "fw-semibold", target: "_top")
          }
        ]
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

    def eligibility_policy_status_key(policy)
      return "fulfilled" if policy.dig(:outcome, :pass)
      return "needs_clarification" if needs_clarification?(policy)

      "not_fulfilled"
    end

    def needs_clarification?(policy)
      POLICY_STATUS_NEEDS_CLARIFICATION_CODES.include?(
        policy.dig(:outcome, :code).to_s
      )
    end

    def prerequisite_campaign_label(policy)
      campaign = policy_config_info(policy)
      return eligibility_requirement_label(policy) if campaign == POLICY_CONFIG_UNAVAILABLE

      campaign
    end

    def prerequisite_not_met_translation_key(context)
      case context
      when :finalization_warning
        "registration.user_registration.eligibility_failures." \
        "prerequisite_not_met_finalization_warning"
      when :finalization_rejection
        "registration.user_registration.eligibility_failures." \
        "prerequisite_not_met_finalization_rejection"
      else
        "registration.user_registration.eligibility_failures.prerequisite_not_met"
      end
    end

    def student_performance_translation_key(context)
      case context
      when :finalization_warning
        "registration.user_registration.eligibility_failures." \
        "student_performance_failed_finalization_warning"
      when :finalization_rejection
        "registration.user_registration.eligibility_failures." \
        "student_performance_failed_finalization_rejection"
      else
        "registration.user_registration.eligibility_failures." \
        "student_performance_failed"
      end
    end

    def generic_translation_key(context)
      case context
      when :finalization_warning
        "registration.user_registration.eligibility_failures." \
        "generic_finalization_warning_html"
      when :finalization_rejection
        "registration.user_registration.eligibility_failures." \
        "generic_finalization_rejection_html"
      else
        "registration.user_registration.eligibility_failures.generic_html"
      end
    end

    def eligibility_requirement_label(policy)
      I18n.t("registration.policy.kinds.#{policy[:kind]}",
             default: policy[:kind].to_s.humanize).downcase
    end
end
