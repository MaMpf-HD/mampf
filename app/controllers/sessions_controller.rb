class SessionsController < Devise::SessionsController
  # Removes the flash message that Devise sets on successful sign in
  def create
    return create_for_turbo_stream if request.format.turbo_stream?

    super
    session[:show_login_transition] = true
    flash.clear
  end

  private

    def create_for_turbo_stream
      self.resource = warden.authenticate(auth_options)

      if resource.present?
        session[:show_login_transition] = true
        flash.clear
        sign_in(resource_name, resource)
        respond_with(resource, location: after_sign_in_path_for(resource))
        return
      end

      self.resource = resource_class.new(sign_in_params)
      flash.now[:alert] = failure_message
      render turbo_stream: stream_flash, status: :unprocessable_content
    end

    def failure_message_key
      message = request.env["warden"]&.message ||
                request.env["warden.options"]&.[](:message)
      return :last_attempt if last_attempt_warning?
      return :locked if message.to_sym == :invalid && attempted_user&.access_locked?
      return message if message.present?
      return :locked if attempted_user&.access_locked?

      :invalid
    end

    def failure_message
      return I18n.t("devise.failure.#{failure_message_key}") unless failure_message_key == :locked

      I18n.t("devise.failure.#{locked_message_key}", unlock_in: unlock_in_words)
    end

    def attempted_user
      authentication_hash = sign_in_params.to_h.slice(*authentication_keys)
      return if authentication_hash.empty?

      resource_class.find_for_database_authentication(authentication_hash)
    end

    def authentication_keys
      Array(resource_class.authentication_keys).map(&:to_s)
    end

    def last_attempt_warning?
      return false unless Devise.last_attempt_warning

      attempted_user&.failed_attempts == resource_class.maximum_attempts - 1
    end

    def locked_message_key
      case Devise.unlock_strategy
      when :email
        :locked_with_email
      when :time
        :locked_with_time
      else
        :locked_with_email_and_time
      end
    end

    def unlock_in_words
      helpers.distance_of_time_in_words(Time.current, Time.current + Devise.unlock_in)
    end
end
