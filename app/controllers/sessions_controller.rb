class SessionsController < Devise::SessionsController
  # Login throttle keyed by IP + email so users behind a shared campus NAT are
  # not collectively limited; only repeated attempts against the SAME account
  # from the SAME source are throttled. Cache-backed (mem_cache_store in prod).
  rate_limit to: 10, within: 1.minute, only: :create,
             by: -> { "#{request.remote_ip}:#{params.dig(:user, :email).to_s.downcase}" },
             with: -> { respond_with_flash(:alert, I18n.t("devise.failure.invalid")) }

  # Removes the flash message that Devise sets on successful sign in
  def create
    super
    session[:show_login_transition] = true
    flash.clear
  end

  # Renders an invalid login message as a flash message via Turbo Streams
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
      respond_with_flash(:alert, I18n.t("devise.failure.invalid"))
    else
      super
    end
  end
end
