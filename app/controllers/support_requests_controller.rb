# Sends a message from the support button to the support address. Also open to
# visitors who are not signed in, since the button is on the login page for
# those who cannot sign in.
class SupportRequestsController < ApplicationController
  THROTTLE_WINDOW = 1.hour

  skip_before_action :authenticate_user!, :enforce_password_change,
                     :enforce_personal_data, only: :create

  # Without a limit, the form would mail the support address any number of
  # times, and it is open to anybody.
  rate_limit to: 5, within: THROTTLE_WINDOW, only: :create,
             by: -> { current_user&.id || request.remote_ip },
             with: lambda {
               render_form(SupportRequest.new(support_request_params), :too_many_requests,
                           throttled: throttled_message(THROTTLE_WINDOW))
             }

  def create
    support_request = SupportRequest.new(support_request_params)
    support_request.user = current_user

    return render_form(support_request, :unprocessable_content) unless support_request.valid?

    details = support_request.attributes.merge("user_id" => current_user&.id)
    SupportRequestMailer.with(support_request: details).new_support_request_email.deliver_later
    render turbo_stream: turbo_stream.update(
      "support-request-body", partial: "support_requests/sent"
    )
  end

  private

    def support_request_params
      params.expect(support_request: [:message, :email, :page])
    end

    def render_form(support_request, status, throttled: nil)
      render turbo_stream: turbo_stream.update(
        "support-request-body",
        partial: "support_requests/form",
        locals: { support_request: support_request, throttled: throttled }
      ), status: status
    end
end
