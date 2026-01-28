module Registration
  class UserRegistration
    class LectureFcfsEditService < UserRegistration::Handler
      def register!
        ActiveRecord::Base.transaction do
          @item.lock!
          errors = validate_register
          return Result.new(false, errors) unless errors.empty?

          registrations = Registration::UserRegistration.where(registration_campaign: @campaign,
                                                               user: @user)
          registrations.destroy_all

          Registration::UserRegistration.create!(
            registration_campaign: @campaign,
            registration_item: @item,
            user: @user,
            status: :confirmed
          )
        end
        Result.new(true, [])
      end

      # hard delete the result, or else cannot trace the "submitted options"
      # the downside effect is that we cannot trace the withdraw time of user
      def withdraw!
        ActiveRecord::Base.transaction do
          @item.lock!
          errors = validate_withdraw
          return Result.new(false, errors) unless errors.empty?

          registration = @item.user_registrations.find_by!(user: @user, status: :confirmed)
          registration.destroy!
        end
        Result.new(true, [])
      end

      private

        # Validation for creating registration in lecture based registration
        # 0. Check open for registration
        # 1. Check if user has already registered for this campaign
        # 2. Check if item still has capacity
        # 3. Check if user satisfies all policies (phase: registration and both)
        def validate_register
          [
            check_campaign_open_for_registrations,
            check_already_registered,
            check_capacity,
            check_policies
          ].compact
        end

        # Validation for withdrawing registration in lecture based registration
        # 0. Check open to withdraw
        # 1. Check if withdrawing current campaign may lead to fail in another "confirmed" campaign
        def validate_withdraw
          [
            check_campaign_open_for_withdraw,
            check_not_referenced_as_prerequisite
          ].compact
        end
    end
  end
end
