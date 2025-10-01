# Helpers for managing flash messages in controllers.
module Flash
  # Renders a flash message via Turbo Stream.
  #
  # Usage:
  # You can use :notice, :success, :alert and :error, see flash/_message.html.erb
  # > flash.now[:success] = "Profile updated"
  # > render_flash
  def render_flash
    return if flash.empty?

    render turbo_stream: turbo_stream.prepend("flash-messages", partial: "flash/message")
  end

  # Renders a flash success message for turbo_stream and html formats.
  # Usage: respond_with_flash_success(I18n.t("feedback.success"))
  def respond_with_flash_success(message, fallback_location: root_path)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:success] = message
        render_flash
      end
      format.html do
        flash.keep[:success] = message
        redirect_back(fallback_location: fallback_location)
      end
    end
  end
end
