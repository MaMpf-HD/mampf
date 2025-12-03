module Registration
  class EligibilityService
    def initialize(campaign, user, phase_scope: :registration)
      @campaign = campaign
      @user = user
      @phase_scope = phase_scope
    end

    def call
      return lecture_based_eligibility if @campaign.campaignable_type == "Lecture"

      raise(NotImplementedError)
    end

    def lecture_based_eligibility
      phases = case @phase_scope.to_sym
               when :registration then [:registration, :both]
               when :finalization then [:finalization, :both]
               else [phase_scope]
      end
      eligibility = phases.flat_map do |ph|
        PolicyEngine.new(@campaign).full_trace_with_config_for(@user, phase: ph)
      end

      eligibility.each do |policy_trace|
        next unless policy_trace[:kind] == "prerequisite_campaign"

        prereq_campaign_id = policy_trace[:config][:prerequisite_campaign_id]
        prereq_campaign = Registration::Campaign.find_by(id: prereq_campaign_id)
        policy_trace[:config]["prerequisite_campaign_info"] = "TODO" if prereq_campaign
      end
      eligibility
    end
  end
end
