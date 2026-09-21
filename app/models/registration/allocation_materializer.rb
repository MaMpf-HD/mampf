module Registration
  class AllocationMaterializer
    def initialize(campaign)
      @campaign = campaign
    end

    def materialize!
      ActiveRecord::Base.transaction do |transaction|
        pending_notifications = []

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

          pending_notifications << [item.registerable, user_ids]
        end

        transaction.after_commit do
          pending_notifications.each do |registerable, user_ids|
            users = User.where(id: user_ids)
            RosterNotificationMailer.finalized(registerable, users)
          end
        end
      end
    end
  end
end
