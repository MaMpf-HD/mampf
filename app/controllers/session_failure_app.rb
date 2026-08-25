# Keeps every failed sign-in on the same message.
#
# An inactive account never reaches SessionsController -- Devise redirects and
# writes its own flash, which would name the reason and so confirm that the
# password was right.
class SessionFailureApp < Devise::FailureApp
  private

    def i18n_message(default = nil)
      return super unless sign_in_attempt?

      I18n.t("devise.failure.invalid")
    end

    def sign_in_attempt?
      request.post? && attempted_path.to_s.start_with?(user_session_path)
    end
end
