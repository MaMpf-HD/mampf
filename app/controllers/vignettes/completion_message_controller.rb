module Vignettes
  class CompletionMessageController < ApplicationController
    before_action :set_lecture, only: [:set_completion_message, :destroy]

    def set_completion_message
      return unless current_user.can_edit?(@lecture)

      @completion_message = CompletionMessage.find_or_initialize_by(lecture: @lecture)
      @completion_message.content = completion_message_params[:content]

      if @completion_message.save
        redirect_back(fallback_location: edit_lecture_path(@lecture),
                      notice: t("vignettes.completion_message.set_success"))
      else
        redirect_back(fallback_location: edit_lecture_path(@lecture),
                      alert: t("vignettes.completion_message.set_failure"))
      end
    end

    def destroy
      return unless current_user.can_edit?(@lecture)

      @completion_message = @lecture.vignettes_completion_message
      if @completion_message&.destroy
        redirect_back(fallback_location: edit_lecture_path(@lecture),
                      notice: t("vignettes.completion_message.delete_success"))
      else
        redirect_back(fallback_location: edit_lecture_path(@lecture),
                      alert: t("vignettes.completion_message.delete_failure"))
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find(params[:id])
      end

      def completion_message_params
        params.permit(:content)
      end
  end
end
