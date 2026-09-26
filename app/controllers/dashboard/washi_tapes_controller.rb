module Dashboard
  # Saves the washi tape color for one of a student's dashboard cards.
  class WashiTapesController < ApplicationController
    def update
      lecture = dashboard_lecture
      return head(:not_found) unless lecture

      color = params.expect(washi_tape: [:tape_color])[:tape_color]
      return head(:unprocessable_content) unless save_color(lecture, color)

      head :no_content
    end

    private

      # A double click sends two requests that both find no row yet; the
      # second insert hits the unique index and updates the first one's row.
      def save_color(lecture, color)
        CardStyle.find_or_initialize_by(user: current_user, lecture: lecture)
                 .update(tape_color: color)
      rescue ActiveRecord::RecordNotUnique
        CardStyle.find_by!(user: current_user, lecture: lecture).update(tape_color: color)
      end

      def dashboard_lecture
        id = params[:lecture_id]

        current_user.roster_lectures.find_by(id: id) ||
          current_user.lectures.find_by(id: id) ||
          current_user.lectures_with_registration_application.find_by(id: id) ||
          Lecture.where(id: id)
                 .where(id: current_user.talks.select(:lecture_id))
                 .first
      end
  end
end
