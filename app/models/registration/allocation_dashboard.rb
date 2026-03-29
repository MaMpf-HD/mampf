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

        registerable_class = first_registerable_class
        return [] unless registerable_class&.exclusive_assignment?

        registered_user_ids = @campaign.user_registrations.pluck(:user_id)
        return [] if registered_user_ids.empty?

        lecture = @campaign.campaignable
        siblings = lecture.public_send(registerable_class.model_name.plural)

        allocated_map = {}
        siblings.find_each do |sibling|
          (sibling.allocated_user_ids & registered_user_ids).each do |uid|
            allocated_map[uid] = sibling
          end
        end

        return [] if allocated_map.empty?

        registrations_by_user = @campaign.user_registrations
                                         .where(user_id: allocated_map.keys)
                                         .includes(:user)
                                         .index_by(&:user_id)

        allocated_map.map do |uid, registerable|
          {
            user: registrations_by_user[uid]&.user,
            registerable: registerable,
            registration: registrations_by_user[uid]
          }
        end
      end

      def first_registerable_class
        type_name = @campaign.registration_items.pick(:registerable_type)
        type_name&.constantize
      rescue NameError
        nil
      end
  end
end
