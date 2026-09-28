# Sends a message from the support button to the support address. Open to
# everybody, signed in or not: whoever cannot get in needs support most.
class SupportRequestsController < ApplicationController
  skip_before_action :authenticate_user!, :enforce_password_change,
                     :enforce_personal_data, only: :create

  # Without a limit, the form would mail the support address any number of
  # times, and it is open to anybody.
  rate_limit to: 5, within: 1.hour, only: :create,
             by: -> { current_user&.id || request.remote_ip },
             with: lambda {
               render_form(SupportRequest.new(support_request_params), :too_many_requests,
                           throttled: true)
             }

  def create
    support_request = SupportRequest.new(support_request_params)
    support_request.user = current_user

    return render_form(support_request, :unprocessable_content) unless support_request.valid?

    request = support_request.attributes.merge("user_id" => current_user&.id)
    SupportRequestMailer.with(support_request: request).new_support_request_email.deliver_later
    render turbo_stream: turbo_stream.update(
      "support-request-body", partial: "support_requests/sent"
    )
  end

  private

    def support_request_params
      params.expect(support_request: [:message, :email, :page])
    end

    def render_form(support_request, status, throttled: false)
      render turbo_stream: turbo_stream.update(
        "support-request-body",
        partial: "support_requests/form",
        locals: { support_request: support_request, throttled: throttled }
      ), status: status
    end
end
