module Registration
  class AllocationMaterializer
    def initialize(campaign)
      @campaign = campaign
    end

    def materialize!
      @campaign.registration_items.includes(:registerable).find_each do |item|
        # Delegate the actual creation of domain objects (e.g. TutorTutorialUser)
        # to the registerable model (e.g. Tutorial).
        # This assumes the registerable implements `materialize_allocation!`.
        user_ids = item.confirmed_user_ids

        item.registerable.materialize_allocation!(
          user_ids: user_ids,
          campaign: @campaign
        )

        # Mark the registrations as materialized
        # We only mark those that were actually confirmed/allocated.
        # rubocop:disable Rails/SkipsModelValidations
        item.user_registrations.where(user_id: user_ids)
            .update_all(materialized_at: Time.current)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
