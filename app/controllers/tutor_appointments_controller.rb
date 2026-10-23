# Lets the staff of a lecture make somebody a tutor by the exact address of
# their confirmed account, besides a tutor voucher, and remove a tutor who
# came either way.
class TutorAppointmentsController < ApplicationController
  before_action :set_lecture

  def current_ability
    @current_ability ||= TutorAppointmentAbility.new(current_user)
  end

  def create
    authorize! :create, @lecture.tutor_appointments.build
    email = params[:email].to_s.strip
    user = User.confirmed.find_by(email: email.downcase)
    unless user
      return render_tutors(email: email, error: t(".no_account"),
                           status: :unprocessable_content)
    end

    added = !user.in?(@lecture.eligible_as_tutors) && appoint(user)
    flash.now[:notice] = t(added ? ".added" : ".already", name: user.tutorial_name)
    render_tutors
  end

  def destroy
    authorize! :destroy, TutorAppointment.new(lecture: @lecture)
    @lecture.remove_waiting_tutor(User.find(params[:user_id]))
    render_tutors
  end

  private

    # Appoints the user and tells them; false when a request sent at the same
    # time appointed them first.
    def appoint(user)
      @lecture.tutor_appointments.create!(user: user)
      LectureNotifier.notify_new_tutor_by_mail(user, @lecture)
      true
    rescue ActiveRecord::RecordNotUnique
      false
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors.of_kind?(:user_id, :taken)

      false
    end

    def set_lecture
      @lecture = Lecture.find(params[:lecture_id])
    end

    def render_tutors(email: nil, error: nil, status: :ok)
      streams = [turbo_stream.replace("lecture-tutors",
                                      partial: "lectures/edit/tutors",
                                      locals: { lecture: @lecture, email: email, error: error })]
      if flash.now[:notice]
        streams << turbo_stream.prepend("flash-messages", partial: "flash/message")
      end
      render turbo_stream: streams, status: status
    end
end
