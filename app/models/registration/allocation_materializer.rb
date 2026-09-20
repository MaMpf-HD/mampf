module Registration
  class AllocationMaterializer
    def initialize(campaign)
      @campaign = campaign
    end

    def materialize!
      pending_notifications = []

      ActiveRecord::Base.transaction do
        @campaign.registration_items.includes(:registerable).find_each do |item|
          user_ids = item.confirmed_user_ids
          next if user_ids.empty?

          item.registerable.materialize_allocation!(
            user_ids: user_ids,
            campaign: @campaign
          )

          # rubocop:disable Rails/SkipsModelValidations
          item.user_registrations.where(user_id: user_ids)
              .update_all(materialized_at: Time.current)
          # rubocop:enable Rails/SkipsModelValidations

          pending_notifications << [item.registerable, user_ids]
        end
      end

      pending_notifications.each do |registerable, user_ids|
        RosterNotificationMailer.finalized(registerable, User.where(id: user_ids))
      end
    end
  end
end
