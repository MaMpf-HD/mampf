module Registration
  # Bulk equivalent of Lecture#registration_status_for, for a page of
  # lectures (the search result cards render many at once): answered in a
  # fixed, small number of queries rather than one per card, which would
  # N+1. Mirrors that method's precedence rules exactly - the two must stay
  # in sync (see the shared spec examples).
  class StatusQuery
    def initialize(user, lecture_ids)
      @user = user
      @lecture_ids = lecture_ids.to_a
    end

    # lecture_id => :confirmed / :pending / :open / :rejected, or absent
    # when the lecture has no non-draft registration campaign at all.
    def statuses
      return {} if @lecture_ids.empty?

      campaigns_by_lecture.each_with_object({}) do |(lecture_id, campaigns), result|
        regs = campaigns.flat_map { |campaign| registrations_by_campaign[campaign.id] || [] }

        status =
          if regs.any? { |reg| reg.status == "confirmed" }
            :confirmed
          elsif regs.any? { |reg| reg.status == "pending" }
            :pending
          elsif campaigns.any?(&:open_for_registrations?)
            :open
          elsif regs.any? { |reg| reg.status == "rejected" && reg.dismissed_at.nil? }
            :rejected
          end

        result[lecture_id] = status if status
      end
    end

    private

      def campaigns_by_lecture
        @campaigns_by_lecture ||= Registration::Campaign
                                  .where(campaignable_type: "Lecture",
                                         campaignable_id: @lecture_ids)
                                  .where.not(status: :draft)
                                  .group_by(&:campaignable_id)
      end

      def registrations_by_campaign
        @registrations_by_campaign ||= Registration::UserRegistration
                                       .where(user: @user,
                                              registration_campaign_id:
                                               campaigns_by_lecture.values.flatten.map(&:id))
                                       .group_by(&:registration_campaign_id)
      end
  end
end
