module StudentPerformance
  class AchievementsController < ApplicationController
    include StudentPerformance::LectureScoped

    before_action :set_achievement, only: [:show, :update, :destroy]
    before_action :require_turbo_stream, only: [:create, :update, :destroy]

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
        format.html do
          redirect_to lecture_student_performance_achievements_path(
            @lecture
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
        format.html do
          redirect_to lecture_student_performance_achievements_path(
            @lecture
          )
        end
      end
    end

    def create
      @achievement = @lecture.achievements.build(achievement_params)

      if @achievement.save
        render turbo_stream: turbo_stream.update(
          "assessments_container",
          ::AchievementDashboardComponent.new(
            achievement: @achievement,
            lecture: @lecture
          )
        )
      else
        render turbo_stream: turbo_stream.update(
          "assessments_container",
          partial: "student_performance/achievements/form",
          locals: { achievement: @achievement, lecture: @lecture }
        ), status: :unprocessable_content
      end
    end

    def update
      original_achievement = @achievement.dup

      if @achievement.update(achievement_params)
        flash.now[:success] = I18n.t("assessment.achievements.flash.updated")
        render turbo_stream: [
          turbo_stream.update(
            "assessments_container",
            ::AchievementDashboardComponent.new(
              achievement: @achievement,
              lecture: @lecture
            )
          ),
          stream_flash
        ]
      else
        render turbo_stream: turbo_stream.update(
          "assessments_container",
          ::AchievementDashboardComponent.new(
            achievement: @achievement,
            lecture: @lecture,
            original_achievement: original_achievement
          )
        ), status: :unprocessable_content
      end
    end

    def destroy
      @achievement.destroy

      if @achievement.destroyed?
        flash.now[:success] = I18n.t("assessment.achievements.flash.destroyed")
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
        # `restrict_with_error` phrases this in table names; the only thing that
        # can block a deletion here is a rule that needs the achievement.
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
        ], status: :unprocessable_content
      end
    end

    private

      # These actions answer with a Turbo Stream and nothing else. Saying so is
      # more honest than handing a hand-written request a document it did not ask
      # for.
      def require_turbo_stream
        head :not_acceptable unless request.format.turbo_stream?
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
        params.expect(
          achievement: [:title, :value_type, :threshold, :description]
        )
      end
  end
end
