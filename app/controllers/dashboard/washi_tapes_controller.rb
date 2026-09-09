module Dashboard
  # Saves the colour a student wants one of their dashboard cards taped up in.
  #
  # A card is on the dashboard because the student holds a place on the
  # lecture's roster, gives one of its talks, or has bookmarked it, so that is
  # what may be styled — checking it here is the whole of the authorization.
  class WashiTapesController < ApplicationController
    def update
      lecture = dashboard_lecture
      return head(:not_found) unless lecture

      # An unknown value would make the enum raise rather than refuse, so it is
      # turned away before it reaches the record.
      color = params.expect(washi_tape: [:tape_color])[:tape_color]
      return head(:unprocessable_content) unless color.in?(WashiTape::COLORS)

      CardStyle.find_or_initialize_by(user: current_user, lecture: lecture)
               .update!(tape_color: color)

      head :no_content
    end

    private

      def dashboard_lecture
        id = params[:lecture_id]

        current_user.enrolled_lectures.find_by(id: id) ||
          current_user.lectures.find_by(id: id) ||
          Lecture.where(id: id)
                 .where(id: current_user.talks.select(:lecture_id))
                 .first
      end
  end
end
