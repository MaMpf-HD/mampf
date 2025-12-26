module Registration
  class UserRegistration
    class LecturePreferenceEditService < UserRegistration::Handler
      def update!(pref_items)
        ActiveRecord::Base.transaction do
          errors = validate_update
          return Result.new(false, errors) unless errors.empty?

          registrations_current_campaign = @campaign.user_registrations.where(user_id: @user.id)
          registrations_current_campaign.destroy_all
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
        def validate_update
          [
            check_campaign_open_for_registrations,
            check_campaign_open_for_withdraw,
            check_policies
          ].compact
        end
    end
  end
end
