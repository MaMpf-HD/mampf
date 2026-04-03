module Rosters
  # Encapsulates the logic for querying registerable entities (Tutorials, Cohorts, Talks)
  # that are not associated with any active registration campaigns.
  class NoCampaignRegisterablesQuery
    def initialize(lecture)
      @lecture = lecture
    end

    def call
      active_campaign_ids = @lecture.registration_campaigns
                                    .where.not(status: :completed)
                                    .select(:id)

      active_items = Registration::Item
                     .where(registration_campaign_id: active_campaign_ids)

      tutorials = @lecture.tutorials.includes(:tutors).where(
        skip_campaigns: true
      ).or(
        @lecture.tutorials.where.not(
          id: active_items.where(registerable_type: "Tutorial")
                          .select(:registerable_id)
        )
      )

      talks = @lecture.talks.includes(:speakers).where(
        skip_campaigns: true
      ).or(
        @lecture.talks.where.not(
          id: active_items.where(registerable_type: "Talk")
                          .select(:registerable_id)
        )
      )

      cohorts = @lecture.cohorts.where.not(
        id: active_items.where(registerable_type: "Cohort")
                        .select(:registerable_id)
      )

      (tutorials.to_a + cohorts.to_a + talks.to_a)
        .sort_by { |registerable| registerable.title.to_s.downcase }
    end
  end
end
