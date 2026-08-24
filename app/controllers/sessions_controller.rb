class SessionsController < Devise::SessionsController
  THROTTLE_WINDOW = 1.minute

  # Login throttle keyed by IP + email so users behind a shared campus NAT are
  # not collectively limited; only repeated attempts against the SAME account
  # from the SAME source are throttled. Cache-backed (mem_cache_store in prod).
  rate_limit to: 10, within: THROTTLE_WINDOW, only: :create,
             by: -> { "#{request.remote_ip}:#{throttle_email}" },
             with: -> { respond_with_flash(:alert, throttled_message(THROTTLE_WINDOW)) }

  # Removes the flash message that Devise sets on successful sign in
  def create
    super
    session[:show_login_transition] = true
    flash.clear
    flash[:notice] = t("profile.please_update") if first_sign_in?(current_user)
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

    # `signed_in?` re-runs the strategies, and with them the password check
    # that just failed; the session already knows the answer.
    failed = request.post? && !warden.authenticated?(resource_name)
    flash.now[:alert] = failure_message if failed

    if failed && request.format.turbo_stream?
      render turbo_stream: stream_flash, status: :unprocessable_content
    else
      super
    end
  end

  private

    # Whether the submitted credentials are the right ones and only the lock
    # stands in the way.
    #
    # Everyone else keeps seeing the generic failure. `config.paranoid` makes
    # failed logins indistinguishable, and reporting the lock to whoever asks
    # would hand out an account-existence oracle: lock any address with five
    # wrong passwords, and the answer tells you whether it is registered.
    def locked_out_with_correct_password?
      user = attempted_user
      password = sign_in_params[:password].to_s
      return user.valid_password?(password) if user&.access_locked?

      # Hash it anyway. Devise does the same for addresses it cannot find
      # (see its database_authenticatable strategy): hashing only for locked
      # accounts would make them the slower answer, and slow means "exists".
      resource_class.new.password = password
      false
    end

    def failure_message
      return I18n.t("devise.failure.invalid") unless locked_out_with_correct_password?

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
end
