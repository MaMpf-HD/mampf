module Vignettes
  class CodenamesController < ApplicationController
    before_action :set_lecture, only: [:set_codename]
    def set_codename
      @codename = Codename.find_or_initialize_by(user: current_user, lecture: @lecture)
      @codename.pseudonym = codename_params[:pseudonym]
      if @codename.save
        redirect_to lecture_questionnaires_path(@lecture),
                    notice: t("vignettes.codenames.set_success")
      else
        redirect_to lecture_questionnaires_path(@lecture), alert: t("vignettes.codenames.set_error")
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find(params[:id])
      end

      def codename_params
        params.permit(:pseudonym)
      end
  end
end
