class LectureNotificationMailer < ApplicationMailer
  before_action { NotificationMailer.sender_and_locale(params[:locale]) }

  def new_editor_email
    @lecture = params[:lecture]
    @recipient = params[:recipient]
    @username = @recipient.tutorial_name

    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.new_editor_subject",
                    title: @lecture.title_for_viewers))
  end

  def new_teacher_email
    @lecture = params[:lecture]
    @recipient = params[:recipient]
    @username = @recipient.tutorial_name

    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.new_teacher_subject",
                    title: @lecture.title_for_viewers))
  end

  def previous_teacher_email
    @lecture = params[:lecture]
    @recipient = params[:recipient]
    @username = @recipient.tutorial_name

    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.previous_teacher_subject",
                    title: @lecture.title_for_viewers,
                    new_teacher: @lecture.teacher.tutorial_name))
  end

  def new_speaker_email
    @talk = params[:talk]
    @recipient = params[:recipient]
    @speaker = params[:speaker].info
    @username = @recipient.tutorial_name

    mail(from: @sender,
         to: @recipient.email,
         subject: t("mailer.new_speaker_subject",
                    seminar: @talk.lecture.title,
                    title: @talk.to_label))
  end
end
