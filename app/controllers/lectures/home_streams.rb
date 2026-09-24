module Lectures
  # Turbo Streams for a student's registration step on the lecture home page.
  # Only the parts that step can change are replaced, so a campaign the
  # student is still editing keeps its unsaved preferences and its open fold.
  module HomeStreams
    extend ActiveSupport::Concern

    private

      def lecture_home_streams(lecture, campaign: nil, self_enrollment: false)
        overview = ::UserRegistrations::LectureOverview.new(lecture, current_user)
        details = overview.open_campaigns.map do |open_campaign|
          ::UserRegistrations::CampaignDetailsService.new(open_campaign, current_user).call
        end

        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]
        streams.concat(campaign_streams(details, campaign)) if campaign
        streams.concat(self_enrollment_streams(lecture)) if self_enrollment
        streams << turbo_stream.update(
          "student_registration_participation",
          html: ParticipationComponent.new(lecture: lecture, user: current_user,
                                           overview: overview).render_in(view_context)
        )
        streams << turbo_stream.update("student_registration_jump_links",
                                       partial: "lectures/home/jump_links",
                                       locals: { details: details })
      end

      def campaign_streams(details, campaign)
        campaign_details = details.find { |d| d.campaign.id == campaign.id }
        return [] unless campaign_details

        [:summary, :body].map do |part|
          component = CampaignCardComponent.new(details: campaign_details,
                                                campaign: campaign_details.campaign,
                                                part: part)
          turbo_stream.update(component.public_send(:"#{part}_id"),
                              html: component.render_in(view_context))
        end
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
