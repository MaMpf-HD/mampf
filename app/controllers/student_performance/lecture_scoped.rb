module StudentPerformance
  # Every screen in this namespace hangs off one lecture and is for its editors
  # only. Kept in one place so the three steps cannot drift apart, and so the
  # include list answers which controllers are covered.
  module LectureScoped
    extend ActiveSupport::Concern

    included do
      before_action :set_lecture
      before_action :authorize_lecture
      before_action :use_lecture_locale
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

      def use_lecture_locale
        I18n.locale = @lecture&.locale_with_inheritance || I18n.default_locale
      end
  end
end
