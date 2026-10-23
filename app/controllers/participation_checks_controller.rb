# Asks a student enrolled in a lecture without any group whether they still
# take part, see Rosters::ParticipationCheck.
class ParticipationChecksController < ApplicationController
  layout "devise"
  skip_before_action :store_user_location!

  def show
    @lectures = Rosters::ParticipationCheck.new(current_user).lectures
    return if @lectures.any?

    flash.keep
    redirect_to after_participation_check_path
  end

  def confirm
    current_user.lecture_memberships.find_by(lecture_id: params[:lecture_id])
                &.update!(participation_confirmed_at: Time.current)
    redirect_to participation_check_path, status: :see_other
  end

  private

    def after_participation_check_path
      session.delete(:after_participation_check).presence || root_path
    end
end
