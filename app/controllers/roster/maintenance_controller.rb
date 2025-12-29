module Roster
  # Manages group allocations through a lecture-level overview and a polymorphic
  # item dashboard. Handles student membership visualization and maintenance actions.
  class MaintenanceController < ApplicationController
    before_action :set_lecture, only: [:index]
    before_action :set_rosterable, only: [:show, :update]

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    # GET /lectures/:lecture_id/roster
    def index
      authorize! :edit, @lecture
      @group_type = params[:group_type]&.to_sym || :all
    end

    # GET /:rosterable_type/:rosterable_id/roster
    def show
      authorize! :edit, @lecture
      @active_tab = params[:tab] || "roster"
    end

    # PATCH /:rosterable_type/:rosterable_id/roster
    def update
      authorize! :edit, @lecture
      if @rosterable.update(rosterable_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "roster_maintenance_#{group_type_for_rosterable}",
              view_context.turbo_frame_tag(
                "roster_maintenance_#{group_type_for_rosterable}",
                src: view_context.lecture_roster_path(@lecture,
                                                      group_type: group_type_for_rosterable),
                loading: "lazy"
              ) { "" }
            )
          end
          format.html do
            redirect_to lecture_roster_path(@lecture, group_type: group_type_for_rosterable)
          end
        end
      else
        redirect_to lecture_roster_path(@lecture),
                    alert: @rosterable.errors.full_messages.join(", ")
      end
    end

    private

      def rosterable_params
        params.expect(rosterable: [:managed_by_campaign])
      end

      def group_type_for_rosterable
        case @rosterable
        when Tutorial then :tutorials
        when Talk then :talks
        else :all
        end
      end

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
