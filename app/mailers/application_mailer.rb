class ApplicationMailer < ActionMailer::Base
  # TODO: Change to `prepend_view_path` once the majority of mailer view files
  # live somewhere in app/frontend/ instead of app/views/
  append_view_path "app/frontend/"

  helper EmailHelper
  default from: DefaultSetting::PROJECT_EMAIL
  default "Message-ID" => lambda {
                            "<#{rand.to_s.split(".")[1]}.#{Time.now.to_i}@#{ENV.fetch(
                              "MAILID_DOMAIN", nil
                            )}>"
                          }
  layout "mailer"

  private

    # Configures the template_path for mails such that email views in our
    # custom `app/frontend/` folder structure can be found.
    #
    # Example for `feedback_mailer.rb`:
    #
    # - The default view path is `app/views/`. Inside this folder, the default
    #   Rails convention is to look for a folder with the class name, that is
    #   in our case: "feedback_mailer". That is, we obtain a path like
    #   `app/views/feedback_mailer/`. Inside this folder, Rails will
    #   look for a file that starts with the action name,
    #   e.g. "new_user_feedback_email".
    #
    # - In addition, we've added `app/frontend/` to the view paths. But here,
    #   we DON'T want to have a structure like
    #   `app/frontend/feedback_mailer/new_user_feedback_email.text.erb`
    #   next to our `app/frontend/feedbacks/` folder.
    #
    #   Instead, we modify the template path to just read "feedbacks"
    #   (instead of "feedback_mailer"), therefore obtaining the correct path:
    #   `app/frontend/feedbacks/new_user_feedback_email.text.erb`.
    #
    def mail(headers = {}, &)
      usual_rails_template_path = self.class.name.underscore.pluralize
      custom_template_path = usual_rails_template_path.gsub("_mailer", "")

      headers[:template_path] = Array(headers[:template_path]) \
        << usual_rails_template_path << custom_template_path
      super
    end
end
