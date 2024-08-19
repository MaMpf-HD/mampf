module Notifier
  extend ActiveSupport::Concern

  def notify_new_editor_by_mail(editor, lecture)
    NotificationMailer.with(recipient: editor,
                            locale: editor.locale,
                            lecture: lecture)
                      .new_editor_email.deliver_later
  end

  def notify_new_teacher_by_mail(lecture)
    NotificationMailer.with(recipient: lecture.teacher,
                            locale: lecture.teacher.locale,
                            lecture: lecture)
                      .new_teacher_email.deliver_later
  end

  def notify_previous_teacher_by_mail(previous_teacher, lecture)
    NotificationMailer.with(recipient: previous_teacher,
                            locale: previous_teacher.locale,
                            lecture: lecture)
                      .previous_teacher_email.deliver_later
  end

  def notify_about_teacher_change_by_mail(lecture, previous_teacher)
    notify_new_teacher_by_mail(lecture)
    notify_previous_teacher_by_mail(previous_teacher, lecture)
  end

  def notify_cospeakers_by_mail(speaker, talks)
    talks.each do |talk|
      talk.speakers.each do |cospeaker|
        next if cospeaker == speaker

        NotificationMailer.with(recipient: cospeaker,
                                locale: cospeaker.locale,
                                talk: talk,
                                speaker: speaker)
                          .new_speaker_email.deliver_later
      end
    end
  end
end
