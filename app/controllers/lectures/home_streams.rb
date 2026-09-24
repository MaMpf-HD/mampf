module Lectures
  # Turbo Streams for a student's registration step on the lecture home page.
  # Only the parts that step can change are replaced, so a campaign the
  # student is still editing keeps its unsaved preferences and its open fold,
  # and nothing moves while the student is looking at it.
  module HomeStreams
    extend ActiveSupport::Concern

    private

      def lecture_home_streams(lecture, campaign: nil, self_enrollment: false)
        overview = ::UserRegistrations::LectureOverview.new(lecture, current_user)

        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]
        streams.concat(campaign_streams(campaign)) if campaign&.open_for_registrations?
        streams.concat(self_enrollment_streams(lecture)) if self_enrollment
        streams << turbo_stream.update(
          ParticipationComponent::TARGET,
          html: ParticipationComponent.new(lecture: lecture, user: current_user,
                                           overview: overview).render_in(view_context)
        )
      end

      def campaign_streams(campaign)
        details = ::UserRegistrations::CampaignDetailsService.new(campaign, current_user).call
        summary = CampaignCardComponent.new(details: details, campaign: campaign, part: :summary)
        body = CampaignCardComponent.new(details: details, campaign: campaign, part: :body)
        [turbo_stream.update(summary.summary_id, html: summary.render_in(view_context)),
         turbo_stream.replace(body.body_id, html: body.render_in(view_context))]
      end

      def self_enrollment_streams(lecture)
        rosterables = Array(Rosters::SelfRosterOptionsQuery.new(lecture, current_user).call)
        { summary: SelfEnrollmentComponent::SUMMARY_ID,
          body: SelfEnrollmentComponent::BODY_ID }.map do |part, id|
          turbo_stream.update(
            id, html: SelfEnrollmentComponent.new(lecture: lecture, user: current_user,
                                                  rosterables: rosterables, part: part)
                                             .render_in(view_context)
          )
        end
      end
  end
end
