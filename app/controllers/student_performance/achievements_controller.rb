module StudentPerformance
  class AchievementsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_achievement, only: [:show, :update, :destroy]

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      @achievements = @lecture.achievements.order(:title)
    end

    def show
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "assessments_container",
            ::AchievementDashboardComponent.new(
              achievement: @achievement, lecture: @lecture
            )
          )
        end
      end
    end

    def new
      @achievement = Achievement.new(lecture: @lecture)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "assessments_container",
            partial: "student_performance/achievements/form",
            locals: { achievement: @achievement, lecture: @lecture }
          )
        end
      end
    end

    def create
      @achievement = @lecture.achievements.build(achievement_params)

      if @achievement.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "assessments_container",
              ::AchievementDashboardComponent.new(
                achievement: @achievement,
                lecture: @lecture,
                active_tab: "settings"
              )
            )
          end
          format.html do
            redirect_to lecture_student_performance_achievements_path(
              @lecture
            ), notice: I18n.t("assessment.achievements.flash.created")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "assessments_container",
              partial: "student_performance/achievements/form",
              locals: { achievement: @achievement, lecture: @lecture }
            ), status: :unprocessable_content
          end
          format.html do
            @achievements = @lecture.achievements.order(:title)
            render :index, status: :unprocessable_content
          end
        end
      end
    end

    def update
      if @achievement.update(achievement_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:success] = I18n.t(
              "assessment.achievements.flash.updated"
            )
            render turbo_stream: [
              turbo_stream.update(
                "assessments_container",
                ::AchievementDashboardComponent.new(
                  achievement: @achievement,
                  lecture: @lecture,
                  active_tab: params[:tab] || "settings"
                )
              ),
              stream_flash
            ]
          end
          format.html do
            redirect_to lecture_student_performance_achievements_path(
              @lecture
            ), notice: I18n.t("assessment.achievements.flash.updated")
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "assessments_container",
              ::AchievementDashboardComponent.new(
                achievement: @achievement,
                lecture: @lecture,
                active_tab: params[:tab] || "settings"
              )
            ), status: :unprocessable_content
          end
          format.html do
            @achievements = @lecture.achievements.order(:title)
            render :index, status: :unprocessable_content
          end
        end
      end
    end

    def destroy
      @achievement.destroy

      respond_to do |format|
        format.turbo_stream do
          if @achievement.destroyed?
            flash.now[:success] = I18n.t(
              "assessment.achievements.flash.destroyed"
            )
            render turbo_stream: [
              turbo_stream.update(
                "assessments_container",
                AssessmentsOverviewComponent.new(
                  lecture: @lecture, active_tab: :achievements
                )
              ),
              stream_flash
            ]
          else
            flash.now[:alert] = I18n.t(
              "assessment.achievements.errors.referenced_by_rules"
            )
            render turbo_stream: [
              turbo_stream.update(
                "assessments_container",
                ::AchievementDashboardComponent.new(
                  achievement: @achievement, lecture: @lecture
                )
              ),
              stream_flash
            ]
          end
        end
        format.html do
          if @achievement.destroyed?
            redirect_to lecture_student_performance_achievements_path(
              @lecture
            ), notice: I18n.t("assessment.achievements.flash.destroyed")
          else
            redirect_to lecture_student_performance_achievements_path(
              @lecture
            ), alert: I18n.t(
              "assessment.achievements.errors.referenced_by_rules"
            )
          end
        end
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path,
                    alert: I18n.t("controllers.no_lecture")
      end

      def authorize_lecture
        authorize!(:edit, @lecture)
      end

      def use_lecture_locale
        I18n.locale = @lecture&.locale_with_inheritance || I18n.default_locale
      end

      def set_achievement
        @achievement = @lecture.achievements.find_by(id: params[:id])
        return if @achievement

        redirect_to lecture_student_performance_achievements_path(@lecture),
                    alert: I18n.t(
                      "assessment.achievements.errors.not_found"
                    )
      end

      def achievement_params
        params.require(:achievement).permit(
          :title, :value_type, :threshold, :description
        )
      end
  end
end
