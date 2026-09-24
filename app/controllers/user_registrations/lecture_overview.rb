module UserRegistrations
  # Sorts a lecture's registration campaigns for one student into three places
  # on the lecture home page: what they can still act on, their own standing,
  # and what is over. A campaign moves between them as its deadline passes, so
  # nothing the student did disappears with the registration block.
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

    # Campaigns the student can still register or change in, soonest first.
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

    # What the student has in a campaign before it is finalized: a registration
    # that counts from the moment it was made, or preferences still waiting for
    # the allocation. After finalization the roster and the rejections speak.
    def standings
      campaigns.reject(&:completed?).filter_map do |campaign|
        registrations = registrations_for(campaign)
        if campaign.preference_based?
          pending = registrations.select(&:pending?).sort_by(&:preference_rank)
          Standing.new(campaign: campaign, kind: :preferences, registrations: pending) if
            pending.any?
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
