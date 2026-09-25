module Registration
  # A student's registration status for a whole page of lectures in one fixed
  # number of queries instead of one per lecture; Lecture#registration_status_for
  # asks it for a single lecture.
  class StatusQuery
    # Sort order for the "You are registered for these" section: settled
    # statuses first, then still-open ones, rejected last.
    SORT_PRIORITY = { nil => 0, confirmed: 0, open: 1, pending: 1, rejected: 2 }.freeze

    def self.sort_priority(status)
      SORT_PRIORITY.fetch(status, 0)
    end

    def initialize(user, lecture_ids)
      @user = user
      @lecture_ids = lecture_ids.to_a
    end

    # lecture_id => :confirmed / :pending / :open / :rejected, or absent
    # when the lecture has no non-draft registration campaign at all. Exam
    # campaigns are left out: registering for an exam is not registering for
    # the lecture (see Lecture#open_exam_registration_for for those).
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
                                  .non_exam
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
