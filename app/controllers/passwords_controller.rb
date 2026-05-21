class PasswordsController < Devise::PasswordsController
  prepend_before_action :enable_password_strength_validation, only: [:update]

  private

    def enable_password_strength_validation
      return unless Rails.env.test?

      Current.password_strength_validation_enabled = true
    end
end
