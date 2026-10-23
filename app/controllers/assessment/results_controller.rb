module Assessment
  class ResultsController < ApplicationController
    before_action :set_scope

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    # The results are out even when their mail could not be queued; the
    # control offers them again, and publishing once more sends it.
    def update
      release.publish!
      flash.now[:success] = t("assessment.results_release.flash.published")
      render_release
    rescue ActiveJob::EnqueueError, RedisClient::Error => e
      Rails.logger.error("Results mail could not be queued: #{e.class}: #{e.message}")
      flash.now[:alert] = t("assessment.results_release.flash.mail_failed")
      render_release
    end

    def destroy
      release.withdraw!
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
        @release ||= ResultsRelease.new(exam: @exam, seminar: @seminar)
      end

      # A talk's row marks whether its speaker sees the grade. Only those
      # marks are replaced, so grades and notes typed into other rows stay.
      def render_release
        control = ResultsReleaseComponent.new(exam: @exam, seminar: @seminar)
        streams = [turbo_stream.replace(ResultsReleaseComponent::ID,
                                        html: render_to_string(control))]
        streams += speaker_mark_streams if @seminar
        render turbo_stream: [*streams, stream_flash]
      end

      def speaker_mark_streams
        Participation.where(assessment: release.gradebooks).includes(:assessment)
                     .map do |participation|
          turbo_stream.replace(helpers.dom_id(participation, :shown_to_speaker),
                               partial: "assessment/participations/shown_to_speaker",
                               locals: { participation: participation })
        end
      end
  end
end
