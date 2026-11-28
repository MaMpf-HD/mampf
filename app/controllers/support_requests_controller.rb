# Sends a message from the support button to the address people write to, see
# `SupportMail`. Only for signed-in users: for anybody else there is no address we
# know to be theirs to answer to, so the button shows them where to write
# instead.
class SupportRequestsController < ApplicationController
  include SupportMail

  THROTTLE_WINDOW = 1.hour
  LIMIT = 5
  THROTTLE_KEY = "support-requests".freeze

  # Somebody stuck on these pages is the one who needs to reach the support.
  skip_before_action :enforce_password_change, :enforce_personal_data, only: :create

  def create
    support_request = SupportRequest.new(support_request_params)
    support_request.user = current_user

    return render_form(support_request, :unprocessable_content) unless support_request.valid?

    if support_mail_limit_reached?(THROTTLE_KEY, limit: LIMIT, window: THROTTLE_WINDOW)
      return render_form(support_request, :too_many_requests,
                         throttled: throttled_message(THROTTLE_WINDOW))
    end

    mail = support_mail("Support", to: DefaultSetting::PROJECT_EMAIL,
                                   text: support_request.message)
    unless deliver_support_mail(mail, THROTTLE_KEY)
      return render_form(support_request, :service_unavailable, send_failed: true)
    end

    render turbo_stream: turbo_stream.update(
      "support-request-body",
      partial: "support_requests/sent",
      locals: { support_request: SupportRequest.new }
    )
  end

  private

    def support_request_params
      params.expect(support_request: [:message])
    end

    def render_form(support_request, status, throttled: nil, send_failed: false)
      render turbo_stream: turbo_stream.update(
        "support-request-body",
        partial: "support_requests/form",
        locals: { support_request: support_request, throttled: throttled,
                  send_failed: send_failed }
      ), status: status
    end
end
