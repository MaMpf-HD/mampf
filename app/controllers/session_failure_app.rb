# Keeps every failed sign-in on the same message.
#
# A wrong password is rendered by SessionsController, but an account that is
# merely inactive never reaches it: Devise redirects and writes its own flash,
# which would name the reason ("confirm your email address") and thereby tell
# whoever asked that the password was right.
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
