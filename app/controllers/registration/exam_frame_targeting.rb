module Registration
  # Turbo target resolution shared by the three controllers that render into an
  # exam's registration tab. Kept in one place because the frame ids and the
  # "campaigns_container" default have to agree across all of them.
  module ExamFrameTargeting
    extend ActiveSupport::Concern

    DEFAULT_FRAME_ID = "campaigns_container".freeze

    private

      def target_frame_id
        params[:frame_id].presence || DEFAULT_FRAME_ID
      end

      def exam_campaign_context?
        target_frame_id != DEFAULT_FRAME_ID && @campaign.exam_campaign?
      end
  end
end
