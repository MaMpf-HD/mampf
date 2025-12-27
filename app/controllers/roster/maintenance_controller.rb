module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    before_action :set_lecture, only: [:index]
    before_action :set_rosterable, only: [:show]

    # GET /lectures/:lecture_id/roster
    def index
      authorize! :edit, @lecture
    end

    # GET /:rosterable_type/:rosterable_id/roster
    def show
      authorize! :edit, @lecture
      @active_tab = params[:tab] || "roster"
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("roster.errors.lecture_not_found")
      end

      def set_rosterable
        klass = params[:type].constantize
        param_key = "#{params[:type].underscore}_id"
        @rosterable = klass.find_by(id: params[param_key])
        if @rosterable
          @lecture = @rosterable.lecture
        else
          redirect_to root_path, alert: t("roster.errors.rosterable_not_found")
        end
      end
  end
end
