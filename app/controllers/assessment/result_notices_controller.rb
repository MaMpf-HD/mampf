module Assessment
  # Closes the block a student's new result gets on the lecture home; the
  # result stays in their participation row.
  class ResultNoticesController < ApplicationController
    def update
      participation = Participation.find_by!(id: params[:participation_id], user: current_user)
      raise(ActiveRecord::RecordNotFound) unless participation.result_released?

      participation.update!(result_seen_at: Time.current)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove(NewResultsComponent.dom_id_for(participation))
        end
        format.html { redirect_to lecture_path(participation.assessment.lecture) }
      end
    end
  end
end
