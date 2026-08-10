module RegistrationPolicyHelper
  def available_policy_kinds(campaign, policy)
    kinds = Registration::Policy.kinds.keys
    return kinds if policy.persisted?

    if campaign.registration_policies.institutional_email.exists?
      kinds.delete("institutional_email")
    end
    if campaign.registration_policies.student_performance.exists?
      kinds.delete("student_performance")
    end

    kinds
  end

  def prerequisite_campaign_options(campaign)
    campaign.campaignable
            .registration_campaigns
            .non_exam
            .where.not(id: campaign.id)
            .to_a
  end

  def prerequisite_campaign_preselect(policy, options)
    return policy.prerequisite_campaign_id if policy.prerequisite_campaign_id.present?

    options.first.id if options.one?
  end
end
