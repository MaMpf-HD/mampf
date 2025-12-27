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
        item.registerable.materialize_allocation!(
          user_ids: item.confirmed_user_ids,
          campaign: @campaign
        )
      end
    end
  end
end
