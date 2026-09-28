module StudentPerformance
  # Every screen in this namespace hangs off one lecture and is for its editors
  # only. Kept in one place so the three steps cannot drift apart, and so the
  # include list answers which controllers are covered.
  module LectureScoped
    extend ActiveSupport::Concern

    included do
      before_action :set_lecture
      before_action :authorize_lecture
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: I18n.t("controllers.no_lecture")
      end

      def authorize_lecture
        authorize!(:edit, @lecture)
      end

      # Reuse DuePoints within the request because the assignment
      # deadlines and total points are the same for every student.
      def due_points
        @due_points ||= DuePoints.new(lecture: @lecture)
      end

      # The one field staff reach for when they are looking for a person, on
      # every table that lists them. Matched against the name the row shows,
      # so that a hit never rests on a display name or an address nobody sees.
      def filter_by_name(scope)
        query = params[:q].presence
        return scope unless query

        scope.joins(:user)
             .where("#{Rosters::ParticipantQuery::SHOWN_NAME} ILIKE :q", q: "%#{query}%")
      end

      def evaluator_for(rule)
        Evaluator.new(rule,
                      assignments_complete: @lecture.assignments_complete?,
                      due_points: due_points)
      end
  end
end
