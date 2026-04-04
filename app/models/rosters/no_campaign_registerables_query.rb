module Rosters
  class NoCampaignRegisterablesQuery
    def initialize(lecture)
      @lecture = lecture
    end

    def call
      scopes_by_type.flat_map(&:to_a)
                    .sort_by { |r| r.title.to_s.downcase }
    end

    def scopes_by_type
      active_items = active_campaign_items
      [
        tutorials_scope(active_items),
        cohorts_scope(active_items),
        talks_scope(active_items)
      ]
    end

    private

      def active_campaign_items
        active_campaign_ids = @lecture.registration_campaigns
                                      .where.not(status: :completed)
                                      .select(:id)

        Registration::Item
          .where(registration_campaign_id: active_campaign_ids)
      end

      def tutorials_scope(active_items)
        @lecture.tutorials.includes(:tutors).where(
          skip_campaigns: true
        ).or(
          @lecture.tutorials.where.not(
            id: active_items
              .where(registerable_type: "Tutorial")
              .select(:registerable_id)
          )
        )
      end

      def talks_scope(active_items)
        @lecture.talks.includes(:speakers).where(
          skip_campaigns: true
        ).or(
          @lecture.talks.where.not(
            id: active_items
              .where(registerable_type: "Talk")
              .select(:registerable_id)
          )
        )
      end

      def cohorts_scope(active_items)
        @lecture.cohorts.where.not(
          id: active_items
            .where(registerable_type: "Cohort")
            .select(:registerable_id)
        )
      end
  end
end
