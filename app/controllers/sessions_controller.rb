class SessionsController < Devise::SessionsController
  # Removes the flash message that Devise sets on successful sign in
  def create
    super
    session[:show_login_transition] = true
    flash.clear
  end

  # Renders login failure messages as flash messages via Turbo Streams
  #
  # In the future, we might also want to rework other Devise pages, such that
  # no entire page reloads are necessary. In case we need a lot of customization,
  # we might want to consider using a custom authentication system instead of
  # Devise, see issue #887.
  def respond_with(resource, _opts = {})
    if action_name != "new" && action_name != "create"
      super
      return
    end

    if request.post? && request.format.turbo_stream? && !signed_in?(resource_name)
      flash.now[:alert] = failure_message
      render turbo_stream: stream_flash, status: :unprocessable_content
    else
      super
    end
  end

  private

    def failure_message_key
      user = attempted_user
      message = request.env["warden"]&.message ||
                request.env["warden.options"]&.[](:message)
      return :last_attempt if last_attempt_warning?
      return :locked if message.to_sym == :invalid && user&.access_locked?
      return message if message.present?
      return :locked if user&.access_locked?

      :invalid
    end

    def failure_message
      key = failure_message_key
      return I18n.t("devise.failure.#{key}") unless key == :locked

      lock_key = case Devise.unlock_strategy
                 when :email
                   :locked_with_email
                 when :time
                   :locked_with_time
                 else
                   :locked_with_email_and_time
      end

      I18n.t(
        "devise.failure.#{lock_key}",
        unlock_in: helpers.distance_of_time_in_words(0, Devise.unlock_in)
      )
    end

    def attempted_user
      return @attempted_user if defined?(@attempted_user)

      authentication_hash = sign_in_params.to_h.slice(
        *Array(resource_class.authentication_keys).map(&:to_s)
      )
      @attempted_user = if authentication_hash.empty?
        nil
      else
        resource_class.find_for_database_authentication(authentication_hash)
      end
    end

    def last_attempt_warning?
      return false unless Devise.last_attempt_warning

      attempted_user&.failed_attempts == resource_class.maximum_attempts - 1
    end
end
