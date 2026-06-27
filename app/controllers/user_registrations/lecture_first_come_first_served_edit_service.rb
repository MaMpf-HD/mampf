module UserRegistrations
  # Service for handling user registration and withdrawal in lecture based registration campaign
  # with first-come-first-served policy.
  class LectureFirstComeFirstServedEditService < Handler
    def register!(item)
      ActiveRecord::Base.transaction do
        @campaign.lock!
        item.lock!
        errors = validate_register(item)
        return Result.new(false, errors) unless errors.empty?

        Registration::UserRegistration.create!(
          registration_campaign: @campaign,
          registration_item: item,
          user: @user,
          status: :confirmed
        )
      end
      Result.new(true, [])
    end

    def withdraw!(item)
      ActiveRecord::Base.transaction do
        item.lock!
        errors = validate_withdraw
        return Result.new(false, errors) unless errors.empty?

        registration = item.user_registrations.find_by(user: @user, status: :confirmed)
        unless registration
          return Result.new(false,
                            [I18n.t("registration.user_registration.none")])
        end

        registration.destroy!
      end
      Result.new(true, [])
    end

    private

      def validate_register(item)
        [
          check_first_come_first_served_mode,
          check_campaign_open_for_registrations,
          check_unremovable_roster_assignment,
          check_already_registered_current_type(item),
          check_capacity(item),
          check_policies,
          check_items([item])
        ].compact
      end

      def validate_withdraw
        [
          check_first_come_first_served_mode,
          check_campaign_open_for_withdraw,
          check_not_referenced_as_prerequisite
        ].compact
      end

      def check_first_come_first_served_mode
        return if @campaign.first_come_first_served?

        I18n.t("registration.user_registration.messages.not_first_come_first_served_mode")
      end
  end
end
