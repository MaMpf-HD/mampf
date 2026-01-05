module Registration
  class AllocationDashboard
    attr_reader :campaign

    def initialize(campaign)
      @campaign = campaign
    end

    def stats
      @stats ||= begin
        assignment = @campaign.user_registrations
                              .where(status: :confirmed)
                              .pluck(:user_id, :registration_item_id)
                              .to_h
        Registration::AllocationStats.new(@campaign, assignment)
      end
    end

    def unassigned_students
      @unassigned_students ||= User.where(id: stats.unassigned_user_ids).order(:email)
    end

    def policy_violations
      @policy_violations ||= begin
        guard_result = Registration::FinalizationGuard.new(@campaign).check
        guard_result.success? ? [] : (guard_result.data || [])
      end
    end

    def conflicting_registrations
      @conflicting_registrations ||= calculate_conflicts
    end

    private

      def calculate_conflicts
        return [] unless @campaign.campaignable.is_a?(Lecture)

        registered_user_ids = @campaign.user_registrations.pluck(:user_id)

        existing_memberships = TutorialMembership.joins(:tutorial)
                                                 .where(tutorials: { lecture_id: @campaign.campaignable.id })
                                                 .where(user_id: registered_user_ids)
                                                 .includes(:user, :tutorial)

        registrations_by_user = @campaign.user_registrations
                                         .where(user_id: existing_memberships.map(&:user_id))
                                         .index_by(&:user_id)

        existing_memberships.map do |m|
          {
            user: m.user,
            tutorial: m.tutorial,
            registration: registrations_by_user[m.user_id]
          }
        end
      end
  end
end
