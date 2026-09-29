# Sends a message from the support button to the feedback address. Also open
# to visitors who are not signed in, since the button is on the login page for
# those who cannot sign in.
class SupportRequestsController < ApplicationController
  THROTTLE_WINDOW = 1.hour
  SIGNED_IN_LIMIT = 20
  SIGNED_OUT_LIMIT = 5

  skip_before_action :authenticate_user!, :enforce_password_change,
                     :enforce_personal_data, only: :create

  # Without a limit, the form would mail the feedback address any number of
  # times, and it is open to anybody. Visitors who are not signed in share an
  # address in the university network, so theirs is the tighter one.
  rate_limit to: SIGNED_IN_LIMIT, within: THROTTLE_WINDOW, only: :create,
             name: "signed_in", if: :user_signed_in?,
             by: -> { current_user.id },
             with: -> { render_throttled }
  rate_limit to: SIGNED_OUT_LIMIT, within: THROTTLE_WINDOW, only: :create,
             name: "signed_out", unless: :user_signed_in?,
             by: -> { request.remote_ip },
             with: -> { render_throttled }

  def create
    support_request = SupportRequest.new(support_request_params)
    support_request.user = current_user

    return render_form(support_request, :unprocessable_content) unless support_request.valid?

    details = support_request.attributes.merge("user_id" => current_user&.id)
    SupportRequestMailer.with(support_request: details).new_support_request_email.deliver_later
    render turbo_stream: turbo_stream.update(
      "support-request-body",
      partial: "support_requests/sent",
      locals: { support_request: SupportRequest.new(email: support_request.email) }
    )
  end

  private

    def support_request_params
      params.expect(support_request: [:message, :email])
    end

    def render_throttled
      render_form(SupportRequest.new(support_request_params), :too_many_requests,
                  throttled: throttled_message(THROTTLE_WINDOW))
    end

    def render_form(support_request, status, throttled: nil)
      render turbo_stream: turbo_stream.update(
        "support-request-body",
        partial: "support_requests/form",
        locals: { support_request: support_request, throttled: throttled }
      ), status: status
    end
end
