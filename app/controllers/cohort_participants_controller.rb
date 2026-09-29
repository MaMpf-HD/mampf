# The flexible groups a tutor runs in a lecture, with who is in them. Nothing
# in a cohort is marked, so this list and the mail are all its tutors need.
class CohortParticipantsController < ApplicationController
  before_action :set_lecture

  def current_ability
    @current_ability ||= CohortAbility.new(current_user)
  end

  def index
    @cohorts = if current_user.can_edit?(@lecture)
      @lecture.cohorts.order(:title)
    else
      current_user.given_cohorts.where(context: @lecture)
    end
    @cohort = @cohorts.find_by(id: params[:cohort]) || @cohorts.first
    return redirect_to(lecture_home_path(@lecture)) unless @cohort

    authorize! :participants, @cohort
    render layout: turbo_frame_request? ? "turbo_frame" : "application"
  end

  private

    def set_lecture
      @lecture = Lecture.find(params[:lecture_id])
    end
end
