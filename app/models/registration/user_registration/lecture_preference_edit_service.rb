module Registration
  class UserRegistration
    # Service for handling user registration and withdrawal in lecture based registration campaign 
    # with preference policy.
    class LecturePreferenceEditService < UserRegistration::Handler
      def update!(pref_items)
        ActiveRecord::Base.transaction do
          errors = validate_update(pref_items)
          return Result.new(false, errors) unless errors.empty?

          @campaign.user_registrations.where(user_id: @user.id).destroy_all
          pref_items.each do |pref_item|
            item = Registration::Item.find(pref_item.id)
            Registration::UserRegistration.create!(
              registration_campaign: @campaign,
              registration_item: item,
              user: @user,
              status: :pending,
              preference_rank: pref_item.rank
            )
          end
        end
        Result.new(true, [])
      end

      private

        # Validation for creating registration in lecture based registration
        # 0a. Check open for registration
        # 0b. Check open for withdraw
        # 1. Check if user satisfies all policies (phase: registration and both)
        # 2. Check if items are valid for this campaign
        def validate_update(pref_items)
          [
            check_campaign_open_for_registrations,
            check_campaign_open_for_withdraw,
            check_policies,
            check_items(pref_items)
          ].compact
        end
    end
  end
end
