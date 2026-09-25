module Dashboard
  # Saves the washi tape color for one of a student's dashboard cards.
  class WashiTapesController < ApplicationController
    def update
      lecture = dashboard_lecture
      return head(:not_found) unless lecture

      color = params.expect(washi_tape: [:tape_color])[:tape_color]
      style = CardStyle.find_or_initialize_by(user: current_user, lecture: lecture)
      return head(:unprocessable_content) unless style.update(tape_color: color)

      head :no_content
    end

    private

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
