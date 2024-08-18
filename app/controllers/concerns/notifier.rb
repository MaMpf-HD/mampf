module Notifier
  extend ActiveSupport::Concern

  def notify_new_editor_by_mail(editor, lecture)
    NotificationMailer.with(recipient: editor,
                            locale: editor.locale,
                            lecture: lecture)
                      .new_editor_email.deliver_later
  end

  def notify_new_teacher_by_mail(teacher, lecture)
    NotificationMailer.with(recipient: teacher,
                            locale: teacher.locale,
                            lecture: lecture)
                      .new_teacher_email.deliver_later
  end

  def notify_previous_teacher_by_mail(previous_teacher, lecture)
    NotificationMailer.with(recipient: previous_teacher,
                            locale: previous_teacher.locale,
                            lecture: lecture)
                      .previous_teacher_email.deliver_later
  end

  def notify_about_teacher_change(lecture, previous_teacher)
    notify_new_teacher_by_mail(current_user, lecture)
    notify_previous_teacher_by_mail(previous_teacher, lecture)
  end
end
