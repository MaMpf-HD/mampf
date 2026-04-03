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

      tutorial_ids_in_active = Registration::Item
                               .where(registration_campaign_id: active_campaign_ids)
                               .where(registerable_type: "Tutorial")
                               .select(:registerable_id)

      cohort_ids_in_active = Registration::Item
                             .where(registration_campaign_id: active_campaign_ids)
                             .where(registerable_type: "Cohort")
                             .select(:registerable_id)

      talk_ids_in_active = Registration::Item
                           .where(registration_campaign_id: active_campaign_ids)
                           .where(registerable_type: "Talk")
                           .select(:registerable_id)

      tutorials = @lecture.tutorials.includes(:tutors).where(
        "skip_campaigns = ? OR tutorials.id NOT IN (?)",
        true,
        tutorial_ids_in_active
      )

      talks = @lecture.talks.includes(:speakers).where(
        "skip_campaigns = ? OR talks.id NOT IN (?)",
        true,
        talk_ids_in_active
      )

      cohorts = @lecture.cohorts.where.not(id: cohort_ids_in_active)

      (tutorials.to_a + cohorts.to_a + talks.to_a)
        .sort_by { |registerable| registerable.title.to_s.downcase }
    end
  end
end
