# Sends a message from the support button to the address people write to. Only
# for signed-in users: for anybody else there is no address we know to be
# theirs to answer to, so the button shows them where to write instead.
class SupportRequestsController < ApplicationController
  THROTTLE_WINDOW = 1.hour
  LIMIT = 20

  # Somebody stuck on these pages is the one who needs to reach the support.
  skip_before_action :enforce_password_change, :enforce_personal_data, only: :create

  def create
    support_request = SupportRequest.new(support_request_params)
    support_request.user = current_user

    return render_form(support_request, :unprocessable_content) unless support_request.valid?

    if over_limit?
      return render_form(support_request, :too_many_requests,
                         throttled: throttled_message(THROTTLE_WINDOW))
    end

    details = support_request.attributes.merge("user_id" => current_user.id,
                                               "user_name" => current_user.tutorial_name,
                                               "user_email" => current_user.email)
    SupportRequestMailer.with(support_request: details).new_support_request_email.deliver_later
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

    # Without a limit, the form would mail the project address any number of
    # times. Only messages that go out are counted, so that a form sent back
    # for a mistake does not use one up. Without the cache the count is nil,
    # and the support stays open.
    def over_limit?
      count = Rails.cache.increment("support-requests:#{current_user.id}", 1,
                                    expires_in: THROTTLE_WINDOW)
      count.present? && count > LIMIT
    end

    def render_form(support_request, status, throttled: nil)
      render turbo_stream: turbo_stream.update(
        "support-request-body",
        partial: "support_requests/form",
        locals: { support_request: support_request, throttled: throttled }
      ), status: status
    end
end
