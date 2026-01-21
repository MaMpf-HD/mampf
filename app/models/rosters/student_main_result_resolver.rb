module Rosters
  class StudentMainResultResolver
    def initialize(campaign, user)
      @campaign = campaign
      @user = user
    end

    def succeed_items
      registerable_type = @campaign.registration_items.first&.registerable_type
      resolver = "Rosters::StudentMainResultResolver::#{registerable_type}"
                 .constantize.new(@campaign, @user)
      resolver.succeed_items
    end

    class BaseResolver
      def initialize(campaign, user)
        @campaign = campaign
        @user = user
      end
    end

    class Tutorial < BaseResolver
      def succeed_items
        memberships = TutorialMembership.where(source_campaign_id: @campaign.id, user_id: @user.id)
        return [] unless memberships.any?

        Registration::Item.where(
          registerable_type: "Tutorial",
          registerable_id: memberships.map(&:tutorial_id),
          registration_campaign_id: @campaign.id
        )
      end
    end

    class Cohort < BaseResolver
      def succeed_items
        memberships = CohortMembership.where(source_campaign_id: @campaign.id, user_id: @user.id)
        return [] unless memberships.any?

        Registration::Item.where(
          registerable_type: "Cohort",
          registerable_id: memberships.map(&:cohort_id),
          registration_campaign_id: @campaign.id
        )
      end
    end

    class Talk < BaseResolver
      def succeed_items
        memberships = SpeakerTalkJoin.where(source_campaign_id: @campaign.id, speaker_id: @user.id)
        return [] unless memberships.any?

        Registration::Item.where(
          registerable_type: "Talk",
          registerable_id: memberships.map(&:talk_id),
          registration_campaign_id: @campaign.id
        )
      end
    end

    class Lecture < BaseResolver
      def succeed_items
        memberships = LectureMembership.where(source_campaign_id: @campaign.id, user_id: @user.id)
        return [] unless memberships.any?

        Registration::Item.where(
          registerable_type: "Lecture",
          registerable_id: memberships.map(&:lecture_id),
          registration_campaign_id: @campaign.id
        )
      end
    end
  end
end
