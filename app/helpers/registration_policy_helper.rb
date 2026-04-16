module RegistrationPolicyHelper
  def available_policy_kinds(campaign, policy)
    kinds = Registration::Policy.kinds.except("student_performance").keys
    return kinds if policy.persisted?
    return kinds unless campaign.registration_policies.institutional_email.exists?

    kinds.excluding("institutional_email")
  end
end
