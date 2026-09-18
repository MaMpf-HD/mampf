module StudentMessages
  # Everything a sender may write to in a lecture: everybody at once, or
  # groups picked from the sections the picker lists. Staff see every group
  # of the lecture, a tutor the groups they grade. Each section's counts
  # come from one grouped query; who is in a group is read only when it is
  # picked.
  class Catalog
    HEADINGS = [:tutorials, :talks, :cohorts, :exams, :registrations].freeze

    def initialize(lecture, sender)
      @lecture = lecture
      @sender = sender
    end

    # Everybody in the lecture - on the roster or registered - as one
    # audience; staff only.
    def everyone
      return unless staff?

      @everyone ||= audience("lecture:all", I18n.t("student_message.audiences.everyone"),
                             :lecture, @lecture.registration_mail_recipients)
    end

    # [[heading, [audience, ...]], ...] without the empty headings.
    def sections
      @sections ||= HEADINGS.filter_map do |heading|
        audiences = send(heading)
        [heading, audiences] if audiences.any?
      end
    end

    def audiences
      [everyone, *sections.flat_map(&:last)].compact
    end

    # The audiences behind the keys a form sent, nil if any of them is not
    # the sender's to write to - which refuses the whole message.
    def pick(keys)
      by_key = audiences.index_by(&:key)
      picked = Array(keys).compact_blank.uniq.map { |key| by_key[key] }
      picked.all? ? picked : nil
    end

    # Whether an item of a preference campaign is on offer: before the
    # allocation such an item means everybody who listed it, at any rank.
    def preference_items_offered?
      running_campaigns.any? do |campaign|
        campaign.preference_based? && !campaign.completed? && campaign.registration_items.many?
      end
    end

    # Whoever may edit the lecture - its teacher, its editors, the course's
    # editors, admins - writes as its staff.
    def staff?
      return @staff if defined?(@staff)

      @staff = @sender.can_edit?(@lecture)
    end

    private

      def audience(key, label, heading, users, count: nil)
        Audience.new(key: key, label: label, heading: heading, users: users, count: count)
      end

      def tutorials
        groups = @lecture.tutorials.to_a
        groups.select! { |tutorial| @sender.can_enter_points_in?(tutorial) } unless staff?
        counts = TutorialMembership.where(tutorial_id: groups.map(&:id))
                                   .group(:tutorial_id).distinct.count(:user_id)
        groups.map do |tutorial|
          audience("tutorial:#{tutorial.id}", tutorial.title, :tutorials, tutorial.members,
                   count: counts.fetch(tutorial.id, 0))
        end
      end

      def talks
        return [] unless staff? && @lecture.seminar?

        talks = @lecture.talks.to_a
        counts = SpeakerTalkJoin.where(talk_id: talks.map(&:id))
                                .group(:talk_id).distinct.count(:speaker_id)
        talks.map do |talk|
          audience("talk:#{talk.id}", talk.title, :talks, talk.speakers,
                   count: counts.fetch(talk.id, 0))
        end
      end

      def cohorts
        return [] unless staff?

        cohorts = @lecture.cohorts.to_a
        counts = CohortMembership.where(cohort_id: cohorts.map(&:id))
                                 .group(:cohort_id).distinct.count(:user_id)
        cohorts.map do |cohort|
          audience("cohort:#{cohort.id}", cohort.title, :cohorts, cohort.members,
                   count: counts.fetch(cohort.id, 0))
        end
      end

      def exams
        return [] unless staff?

        exams = @lecture.exams.to_a
        counts = ExamRosterEntry.active.where(exam_id: exams.map(&:id))
                                .group(:exam_id).distinct.count(:user_id)
        exams.map do |exam|
          audience("exam:#{exam.id}", exam.title, :exams, exam.users,
                   count: counts.fetch(exam.id, 0))
        end
      end

      def registrations
        return [] unless staff?

        running_campaigns.flat_map { |campaign| campaign_audiences(campaign) }
      end

      def running_campaigns
        @running_campaigns ||= @lecture.registration_campaigns
                                       .includes(registration_items: :registerable)
                                       .reject(&:draft?)
      end

      # While a campaign runs, its items are the groups - the rosters are only
      # filled at finalization; after it the rosters take over and only the
      # rejected are left to write to. A campaign with one item is that item.
      def campaign_audiences(campaign)
        # By the registerable's own title: Item#title asks each tutorial for
        # its tutors, a query apiece.
        items = campaign.registration_items.sort_by { |item| item.registerable.title }
        name = campaign_name(campaign, items)
        list = []
        unless campaign.completed?
          list << audience("campaign:#{campaign.id}:all",
                           "#{name}: #{I18n.t("student_message.audiences.registered")}",
                           :registrations, registrants(campaign.user_registrations),
                           count: registration_counts.dig(:registered, campaign.id) || 0)
          if items.many?
            items.each do |item|
              list << audience("item:#{item.id}", "#{name}: #{item.registerable.title}",
                               :registrations, registrants(item.user_registrations),
                               count: item_counts.fetch(item.id, 0))
            end
          end
        end
        rejected = registration_counts.dig(:rejected, campaign.id) || 0
        if rejected.positive?
          list << audience("campaign:#{campaign.id}:rejected",
                           "#{name}: #{I18n.t("student_message.audiences.rejected")}",
                           :registrations,
                           User.where(id: campaign.user_registrations.rejected.select(:user_id)),
                           count: rejected)
        end
        list
      end

      # An unnamed campaign for one thing - an exam, mostly - goes by that.
      def campaign_name(campaign, items)
        campaign.description.to_s.strip.presence ||
          (items.one? ? items.first.registerable.title : campaign.student_facing_title)
      end

      def registrants(user_registrations)
        User.where(id: user_registrations.where.not(status: :rejected).select(:user_id))
      end

      # Per campaign, how many registered and how many were rejected: two
      # queries for every campaign of the lecture.
      def registration_counts
        @registration_counts ||= begin
          scope = Registration::UserRegistration
                  .where(registration_campaign_id: running_campaigns.map(&:id))
          { registered: scope.where.not(status: :rejected).group(:registration_campaign_id)
                             .distinct.count(:user_id),
            rejected: scope.rejected.group(:registration_campaign_id).distinct.count(:user_id) }
        end
      end

      def item_counts
        item_ids = running_campaigns.flat_map(&:registration_item_ids)
        @item_counts ||= Registration::UserRegistration
                         .where(registration_item_id: item_ids).where.not(status: :rejected)
                         .group(:registration_item_id).distinct.count(:user_id)
      end
  end
end
