module StudentMessages
  # Everything a sender may write to in a lecture: everybody at once, or
  # groups picked from the sections the picker lists. One place decides
  # what a sender may address, for the preview and for the send alike. The
  # counts are read per section, not per group, so the picker costs the
  # same however many groups a lecture has; who is in a group is read when
  # it is picked.
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
    # the sender's to write to - which refuses the whole message. Everybody
    # next to a group is everybody: the record would otherwise name a group
    # the mail did not single out.
    def pick(keys)
      by_key = audiences.index_by(&:key)
      picked = Array(keys).compact_blank.uniq.map { |key| by_key[key] }
      return unless picked.all?

      picked.include?(everyone) ? [everyone] : picked
    end

    # Whether an item of a preference campaign is on offer: before the
    # allocation such an item means everybody who listed it, at any rank.
    def preference_items_offered?
      running_campaigns.any? do |campaign|
        campaign.preference_based? && !campaign.completed? && campaign.registration_items.many?
      end
    end

    # The lecture's edit right decides, so that a course's editors, who
    # inherit it, write as staff too: in cc, on the lecture's list.
    def staff?
      return @staff if defined?(@staff)

      @staff = @sender.can_edit?(@lecture)
    end

    private

      def audience(key, label, heading, users, count: nil)
        Audience.new(key: key, label: label, heading: heading, users: users, count: count)
      end

      # Outside the staff, only a tutorial's own tutors may write on it - the
      # graders a tutorial inherits are the staff - so the tutor's list is
      # read directly rather than asking every tutorial of the lecture.
      def tutorials
        groups = if staff?
          @lecture.tutorials.to_a
        else
          @sender.given_tutorials.where(lecture: @lecture).to_a
        end
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
          audience("exam:#{exam.id}", group_title(exam), :exams, exam.users,
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
        items = campaign.registration_items.sort_by { |item| group_title(item.registerable) }
        name = campaign_name(campaign, items)
        list = []
        unless campaign.completed?
          list << audience("campaign:#{campaign.id}:all",
                           "#{name}: #{I18n.t("student_message.audiences.registered")}",
                           :registrations, registrants(campaign.user_registrations),
                           count: registered_counts.fetch(campaign.id, 0))
          if items.many?
            items.each do |item|
              list << audience("item:#{item.id}", "#{name}: #{group_title(item.registerable)}",
                               :registrations, registrants(item.user_registrations),
                               count: item_counts.fetch(item.id, 0))
            end
          end
        end
        # The campaign's own rejected queue: not a row with a rejection that
        # was overridden, left by the solver, or beside a registration that
        # went through. One count per campaign; a lecture has few.
        rejected = campaign.open_rejected_registrations
        rejected_count = rejected.distinct.count(:user_id)
        if rejected_count.positive?
          list << audience("campaign:#{campaign.id}:rejected",
                           "#{name}: #{I18n.t("student_message.audiences.rejected")}",
                           :registrations, User.where(id: rejected.select(:user_id)),
                           count: rejected_count)
        end
        list
      end

      # An unnamed campaign for one thing - an exam, mostly - goes by that.
      def campaign_name(campaign, items)
        campaign.description.to_s.strip.presence ||
          (items.one? ? group_title(items.first.registerable) : campaign.student_facing_title)
      end

      # An exam's registration title carries its date, which tells two
      # "Final exam"s apart; a tutorial's would ask for its tutors, a query
      # per item, and the title alone names the group.
      def group_title(registerable)
        registerable.is_a?(Exam) ? registerable.registration_title : registerable.title
      end

      def registrants(user_registrations)
        User.where(id: user_registrations.where.not(status: :rejected).select(:user_id))
      end

      # One query for all campaigns rather than one per campaign.
      def registered_counts
        @registered_counts ||= Registration::UserRegistration
                               .where(registration_campaign_id: running_campaigns.map(&:id))
                               .where.not(status: :rejected)
                               .group(:registration_campaign_id).distinct.count(:user_id)
      end

      def item_counts
        item_ids = running_campaigns.flat_map(&:registration_item_ids)
        @item_counts ||= Registration::UserRegistration
                         .where(registration_item_id: item_ids).where.not(status: :rejected)
                         .group(:registration_item_id).distinct.count(:user_id)
      end
  end
end
