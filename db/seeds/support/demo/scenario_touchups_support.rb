module Demo
  # Small adjustments applied once every other scenario in db/seeds/100_scenarios.rb
  # has run: a campaign still running in the term after the one the seed plays
  # in, the current term's own campaigns settled rather than left half-open,
  # deadlines that do not go stale, and two accounts kept on an outdated
  # password policy so the forced password-change flow has something to
  # demonstrate.
  module ScenarioTouchupsSupport
    extend self

    TUTORIAL_DESCRIPTION = "Anmeldung zu den Übungsgruppen".freeze
    TALK_DESCRIPTION = "Vergabe der Vortragsthemen".freeze
    # Everyone else gets in without the detour.
    STALE_PASSWORD_ACCOUNTS = ["student5@mampf.edu", "moded@mampf.edu"].freeze

    # A registration that is still running belongs in the term that is still
    # being planned. The term the seed plays in is done registering: its
    # lecture has a finalized roster and students sitting in tutorials.
    def add_running_campaigns!
      term = Demo::TermSupport.next_term

      open_campaign!(lecture_for(term), TUTORIAL_DESCRIPTION, items_count: 4,
                                                              capacity: 12)
      open_campaign!(seminar_for(term), TALK_DESCRIPTION, items_count: 8)
    end

    # Registration in the term the seed plays in is over: a campaign left open
    # there would be a registration nobody can finish. Only a campaign that
    # ran its course stays, because that is what its lecture shows.
    def settle_current_term_campaigns!
      Lecture.where(term: Demo::TermSupport.active_term).find_each do |lecture|
        Registration::Campaign.where(campaignable: lecture).find_each do |campaign|
          Demo::CampaignCleanup.discard!(campaign) unless campaign.completed?
        end
      end
    end

    # The scenarios set their deadlines a week out, which does not stay true.
    def extend_open_deadlines!
      # rubocop:disable Rails/SkipsModelValidations
      Registration::Campaign.open.update_all(registration_deadline: 1.year.from_now)
      # rubocop:enable Rails/SkipsModelValidations
    end

    # Seeds::LoadSupport gives every persona a working password, which marks
    # them as following the current password policy; two accounts are put
    # back so there is something to demonstrate the forced-change flow with.
    def stage_password_policy!
      # rubocop:disable Rails/SkipsModelValidations
      User.where(email: STALE_PASSWORD_ACCOUNTS)
          .update_all(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

      def lecture_for(term)
        find_or_create_lecture!(term, "lecture", "Analysis #{label(term)}",
                                "Ana #{label(term)}")
      end

      def seminar_for(term)
        find_or_create_lecture!(term, "seminar", "Seminar #{label(term)}",
                                "Sem #{label(term)}")
      end

      def label(term)
        Demo::TermSupport.label(term)
      end

      def find_or_create_lecture!(term, sort, course_title, short_title)
        Demo::TermSupport.find_or_create_lecture!(
          term: term, teacher: teacher, sort: sort,
          course_title: course_title, short_title: short_title
        )
      end

      def teacher
        @teacher ||= Demo::LectureSupport.teacher!
      end

      def open_campaign!(lecture, description, items_count:, capacity: nil)
        return if Registration::Campaign.exists?(campaignable: lecture,
                                                 description: description)

        FactoryBot.create(:registration_campaign, :open,
                          campaignable: lecture,
                          description: description,
                          registration_deadline: 1.year.from_now,
                          items_count: items_count,
                          capacity: capacity)
      end
  end
end
