module Registration
  # Lets lecture staff send a one-off email (optionally with an
  # attachment) to all registered students of a lecture.
  class StudentMessagesController < ApplicationController
    before_action :set_lecture

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def create
      authorize! :edit, @lecture

      if @lecture.registration_mail_recipients.none?
        return redirect_to edit_lecture_path(@lecture, tab: "communication"),
                           alert: t("registration.student_message.no_recipients")
      end

      @message = Registration::StudentMessage.new(message_params)
      @message.lecture = @lecture
      @message.sender = current_user
      # recipient_emails and recipients_count are snapshotted by the model
      # at creation time

      if @message.save
        StudentMessageMailer.with(message: @message)
                            .student_message_email.deliver_later
        redirect_to edit_lecture_path(@lecture, tab: "communication"),
                    notice: t("registration.student_message.sent",
                              count: @message.recipients_count)
      else
        redirect_to edit_lecture_path(@lecture, tab: "communication"),
                    alert: @message.errors.full_messages.to_sentence
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("registration.lecture.not_found")
      end

      def message_params
        params.expect(registration_student_message: [:subject, :body,
                                                     :attachment])
      end
  end
end
