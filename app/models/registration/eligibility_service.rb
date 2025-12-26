module Registration
  class EligibilityService
    def initialize(campaign, user, phase_scope: :registration)
      @campaign = campaign
      @user = user
      @phase_scope = phase_scope
    end

    def call
      return lecture_based_eligibility if @campaign.lecture_based?

      raise(NotImplementedError)
    end

    def lecture_based_eligibility
      phases = case @phase_scope.to_sym
               when :registration then [:registration, :both]
               when :finalization then [:finalization, :both]
               else [@phase_scope]
      end
      phases.flat_map do |ph|
        PolicyEngine.new(@campaign).full_trace_with_config_for(@user, phase: ph)
      end
    end
  end
end
