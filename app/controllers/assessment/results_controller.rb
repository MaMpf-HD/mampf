module Assessment
  # Publishes the results of an exam, or of a seminar's fully graded talks,
  # to the students, and takes them back.
  class ResultsController < ApplicationController
    before_action :set_scope

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def update
      release.to_publish.each(&:publish_results!)
      flash.now[:success] = t("assessment.results_release.flash.published")
      render_release
    end

    def destroy
      release.published.each(&:withdraw_results!)
      flash.now[:success] = t("assessment.results_release.flash.withdrawn")
      render_release
    end

    private

      # Sheets have no release step, so an exam is the only assessment
      # published on its own.
      def set_scope
        if params[:assessment_id]
          assessment = Assessment.find(params[:assessment_id])
          authorize! :update, assessment
          raise(ActiveRecord::RecordNotFound) unless assessment.assessable.is_a?(Exam)

          @exam = assessment.assessable
        else
          @seminar = Lecture.find(params[:lecture_id])
          authorize! :update, @seminar
          raise(ActiveRecord::RecordNotFound) unless @seminar.seminar?
        end
      end

      def release
        @release ||= ResultsReleaseComponent.new(exam: @exam, seminar: @seminar)
      end

      # A seminar's table comes along whole, as its rows mark which talks
      # the speakers see.
      def render_release
        stream = if @seminar
          table = TalkGradingTableComponent.new(seminar: @seminar)
          turbo_stream.replace("grading-table", html: render_to_string(table))
        else
          turbo_stream.replace(ResultsReleaseComponent::ID,
                               html: render_to_string(ResultsReleaseComponent.new(exam: @exam)))
        end
        render turbo_stream: [stream, stream_flash]
      end
  end
end
