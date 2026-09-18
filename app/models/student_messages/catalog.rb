module StudentMessages
  # Everything a sender may write to in a lecture: everybody at once, or
  # groups picked from the sections the picker lists. Staff see every group
  # of the lecture, a tutor the groups they grade. Nothing here is a query
  # until a count or a pick asks for it.
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

    # Whoever may edit the lecture - its teacher, its editors, the course's
    # editors, admins - writes as its staff.
    def staff?
      return @staff if defined?(@staff)

      @staff = @sender.can_edit?(@lecture)
    end

    private

      def audience(key, label, heading, users)
        Audience.new(key: key, label: label, heading: heading, users: users)
      end

      def tutorials
        groups = @lecture.tutorials
        groups = groups.select { |tutorial| @sender.can_enter_points_in?(tutorial) } unless staff?
        groups.map do |tutorial|
          audience("tutorial:#{tutorial.id}", tutorial.title, :tutorials, tutorial.members)
        end
      end

      def talks
        return [] unless staff? && @lecture.seminar?

        @lecture.talks.map do |talk|
          audience("talk:#{talk.id}", talk.title, :talks, talk.speakers)
        end
      end

      def cohorts
        return [] unless staff?

        @lecture.cohorts.map do |cohort|
          audience("cohort:#{cohort.id}", cohort.title, :cohorts, cohort.members)
        end
      end

      def exams
        return [] unless staff?

        @lecture.exams.map do |exam|
          audience("exam:#{exam.id}", exam.title, :exams, exam.users)
        end
      end

      def registrations
        return [] unless staff?

        @lecture.registration_campaigns.reject(&:draft?).flat_map do |campaign|
          campaign_audiences(campaign)
        end
      end

      # While a campaign runs, its items are the groups - the rosters are only
      # filled at finalization; after it the rosters take over and only the
      # rejected are left to write to. A campaign with one item is that item.
      def campaign_audiences(campaign)
        items = campaign.registration_items.to_a
        name = campaign_name(campaign, items)
        list = []
        unless campaign.completed?
          list << audience("campaign:#{campaign.id}:all",
                           "#{name}: #{I18n.t("student_message.audiences.registered")}",
                           :registrations, registrants(campaign.user_registrations))
          if items.many?
            items.each do |item|
              list << audience("item:#{item.id}", "#{name}: #{item.title}", :registrations,
                               registrants(item.user_registrations))
            end
          end
        end
        rejected = campaign.user_registrations.rejected
        if rejected.exists?
          list << audience("campaign:#{campaign.id}:rejected",
                           "#{name}: #{I18n.t("student_message.audiences.rejected")}",
                           :registrations, User.where(id: rejected.select(:user_id)))
        end
        list
      end

      # An unnamed campaign for one thing - an exam, mostly - goes by that.
      def campaign_name(campaign, items)
        campaign.description.to_s.strip.presence ||
          (items.one? ? items.first.title : campaign.student_facing_title)
      end

      def registrants(user_registrations)
        User.where(id: user_registrations.where.not(status: :rejected).select(:user_id))
      end
  end
end
