module UserRegistrations
  # Sorts a lecture's registration campaigns for one student into those still
  # open, their standing in the others before finalization, and those past
  # their deadline.
  class LectureOverview
    Standing = Struct.new(:campaign, :kind, :registrations, keyword_init: true)

    def initialize(lecture, user)
      @lecture = lecture
      @user = user
    end

    def campaigns
      @campaigns ||= Registration::Campaign.where(campaignable: @lecture)
                                           .where.not(status: :draft)
                                           .includes(registration_items: :registerable)
                                           .order(:registration_deadline)
                                           .to_a
    end

    def open_campaigns
      campaigns.select(&:open_for_registrations?)
    end

    # Campaigns past their window, latest first; shown to those who missed one
    # as well, so a missing registration option has a visible reason.
    def closed_campaigns
      campaigns.reject(&:open_for_registrations?).reverse
    end

    def registrations_for(campaign)
      registrations_by_campaign.fetch(campaign.id, [])
    end

    # A preference campaign keeps showing the ranked choices until it is
    # finalized: the allocation already marks the chosen one confirmed, but that
    # is a proposal, not a place, and the roster only follows at finalization.
    # A first come, first served registration counts from the moment it is made.
    def standings
      campaigns.reject(&:completed?).filter_map do |campaign|
        registrations = registrations_for(campaign).reject(&:rejected?)
        next if registrations.empty?

        if campaign.preference_based?
          ranked = registrations.select(&:preference_rank).sort_by(&:preference_rank)
          Standing.new(campaign: campaign, kind: :preferences, registrations: ranked)
        else
          confirmed = registrations.select(&:confirmed?)
          Standing.new(campaign: campaign, kind: :registered, registrations: confirmed) if
            confirmed.any?
        end
      end
    end

    private

      def registrations_by_campaign
        @registrations_by_campaign ||=
          Registration::UserRegistration.where(user: @user,
                                               registration_campaign_id: campaigns.map(&:id))
                                        .includes(registration_item: :registerable)
                                        .group_by(&:registration_campaign_id)
      end
  end
end
