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

    # Moves the user's confirmed place to another item in one step: the old place
    # is only given up once the new one is secured, so nobody ends up with none.
    def switch!(from_item, to_item)
      ActiveRecord::Base.transaction do
        @campaign.lock!
        [from_item, to_item].sort_by(&:id).each(&:lock!)
        registration = from_item.user_registrations.find_by(user: @user, status: :confirmed)
        errors = validate_switch(from_item, to_item, registration)
        return Result.new(false, errors) unless errors.empty?

        registration.destroy!
        Registration::UserRegistration.create!(
          registration_campaign: @campaign,
          registration_item: to_item,
          user: @user,
          status: :confirmed
        )
      end
      Result.new(true, [])
    end

    private

      def validate_switch(from_item, to_item, registration)
        [
          check_first_come_first_served_mode,
          check_campaign_open_for_registrations,
          (I18n.t("registration.user_registration.none") unless registration),
          check_same_type(from_item, to_item),
          check_unremovable_roster_assignment(joining: to_item.registerable),
          check_capacity(to_item),
          check_policies,
          check_items([from_item, to_item])
        ].compact
      end

      def check_same_type(from_item, to_item)
        return if from_item != to_item && from_item.registerable_type == to_item.registerable_type

        I18n.t("registration.user_registration.messages.invalid_options")
      end

      def validate_register(item)
        [
          check_first_come_first_served_mode,
          check_campaign_open_for_registrations,
          check_unremovable_roster_assignment(joining: item.registerable),
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
