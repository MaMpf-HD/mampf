module Notifier
  extend ActiveSupport::Concern

  def notify_new_editor_by_mail(editor, lecture)
    NotificationMailer.with(recipient: editor,
                            locale: editor.locale,
                            lecture: lecture)
                      .new_editor_email.deliver_later
  end
end
