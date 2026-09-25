module Lectures
  # Turbo Streams for a student's registration step on the lecture home page.
  # They replace only what the step can change, so another campaign the
  # student is still editing keeps its unsaved preferences.
  module HomeStreams
    extend ActiveSupport::Concern

    private

      def lecture_home_streams(lecture, campaign: nil, self_enrollment: false)
        overview = ::UserRegistrations::LectureOverview.new(lecture, current_user)

        streams = [turbo_stream.replace("flash-messages", partial: "flash/messages")]
        streams.concat(campaign_streams(campaign)) if campaign&.open_for_registrations?
        streams.concat(self_enrollment_streams(lecture)) if self_enrollment
        streams.concat(other_campaign_streams(overview, campaign, self_enrollment))
        streams << turbo_stream.update(
          ParticipationComponent::TARGET,
          html: ParticipationComponent.new(lecture: lecture, user: current_user,
                                           overview: overview).render_in(view_context)
        )
      end

      # A step in one place can change what another open campaign allows: it may
      # name this campaign as its prerequisite, or offer tutorials the student
      # may no longer switch to after joining one without leave. Those get their
      # options replaced; every other campaign only its summary, so that its
      # unsaved choices stay.
      def other_campaign_streams(overview, campaign, self_enrollment)
        overview.open_campaigns.reject { |other| other == campaign }.flat_map do |other|
          if affected_by?(other, campaign, self_enrollment)
            campaign_streams(other)
          else
            summary_stream(other, overview)
          end
        end
      end

      def affected_by?(other, campaign, self_enrollment)
        if self_enrollment
          other.registration_items.map(&:registerable).any?(&:roster_exclusive_within_lecture?)
        else
          other.registration_policies.any? do |policy|
            policy.prerequisite_campaign? &&
              policy.prerequisite_campaign_id.to_s == campaign&.id.to_s
          end
        end
      end

      def summary_stream(campaign, overview)
        details = ::UserRegistrations::CampaignDetailsService
                  .new(campaign, current_user)
                  .summary(own_registrations: overview.registrations_for(campaign))
        component = CampaignCardComponent.new(details: details, campaign: campaign,
                                              part: :summary)
        [turbo_stream.update(component.summary_id, html: component.render_in(view_context))]
      end

      def campaign_streams(campaign)
        details = ::UserRegistrations::CampaignDetailsService.new(campaign, current_user).call
        summary = CampaignCardComponent.new(details: details, campaign: campaign, part: :summary)
        body = CampaignCardComponent.new(details: details, campaign: campaign, part: :body)
        [turbo_stream.update(summary.summary_id, html: summary.render_in(view_context)),
         turbo_stream.replace(body.body_id, html: body.render_in(view_context))]
      end

      # Leaving the last group on offer empties the row, and the row goes.
      def self_enrollment_streams(lecture)
        rosterables = Array(Rosters::SelfRosterOptionsQuery.new(lecture, current_user).call)
        return [turbo_stream.remove(SelfEnrollmentComponent::BLOCK_ID)] if rosterables.empty?

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
