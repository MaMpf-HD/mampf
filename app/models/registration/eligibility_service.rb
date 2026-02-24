module Registration
  class EligibilityService
    def initialize(campaign, user, phase_scope: :registration)
      @campaign = campaign
      @user = user
      @phase_scope = phase_scope
    end

    def call
      lecture_based_eligibility
    end

    def lecture_based_eligibility
      PolicyEngine.new(@campaign).full_trace_with_config_for(@user, phase: @phase_scope.to_sym)
    end
  end
end
