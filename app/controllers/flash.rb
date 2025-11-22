# Helpers for managing flash messages in controllers.
module Flash
  # Returns the Turbo Stream to render a flash message.
  #
  # Usage:
  # You can use :notice, :success, :alert and :error, see flash/_message.html.erb
  # > flash[:success] = "Profile updated"
  # > render turbo_stream: stream_flash
  # However, for this scenario, you'd probably rather use `render_flash`.
  #
  # The main use case for this in favor of `render_flash` is when you want
  # to append multiple turbo streams in one response.
  # > render turbo_stream: [turbo_stream.remove(...), stream_flash]
  def stream_flash
    return if flash.empty?

    turbo_stream.prepend("flash-messages", partial: "flash/message")
  end

  # Renders a flash message via Turbo Stream.
  #
  # Usage:
  # You can use :notice, :success, :alert and :error, see flash/_message.html.erb
  # > flash.now[:success] = "Profile updated"
  # > render_flash
  def render_flash
    return if flash.empty?

    render turbo_stream: stream_flash
  end

  # Renders a flash success message for turbo_stream and html formats.
  # Usage: respond_with_flash(:success, I18n.t("feedback.success"))
  def respond_with_flash(flash_type, message, fallback_location: root_path)
    respond_to do |format|
      format.turbo_stream do
        flash.now[flash_type] = message
        render_flash
      end
      format.html do
        flash.keep[flash_type] = message
        redirect_back_or_to(fallback_location)
      end
    end
  end
end
