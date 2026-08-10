module RegistrationPolicyHelper
  def available_policy_kinds(campaign, policy)
    kinds = Registration::Policy.kinds.except("student_performance").keys
    return kinds if policy.persisted?
    return kinds unless campaign.registration_policies.institutional_email.exists?

    kinds.excluding("institutional_email")
  end

  def prerequisite_campaign_options(campaign)
    campaign.campaignable.registration_campaigns.where.not(id: campaign.id).to_a
  end

  def prerequisite_campaign_preselect(policy, options)
    return policy.prerequisite_campaign_id if policy.prerequisite_campaign_id.present?

    options.first.id if options.one?
  end
end
