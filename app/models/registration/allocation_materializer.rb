module Registration
  class AllocationMaterializer
    def initialize(campaign)
      @campaign = campaign
    end

    def materialize!
      ActiveRecord::Base.transaction do
        @campaign.registration_items.includes(:registerable).find_each do |item|
          user_ids = item.confirmed_user_ids

          item.registerable.materialize_allocation!(
            user_ids: user_ids,
            campaign: @campaign
          )

          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user_id: user_ids)
              .update_all(materialized_at: Time.current)
          # rubocop:enable Rails/SkipsModelValidations
        end
      end
    end
  end
end
