module Demo
  # Sets up the demo scenario for the Müsli-transition preview (PR #1171):
  # a published lecture in the *next* term whose content is gated by a
  # passphrase, with an open first-come-first-served tutorial campaign.
  #
  # This stages the full student journey end to end:
  # dashboard banner -> next-semester search (badge "Registration open")
  # -> lecture home -> register -> (teacher finalizes) -> auto-subscribed
  # (passphrase waived for roster members) -> content unlocks.
  module TransitionPreviewSupport
    extend self

    COURSE_TITLE = "Demo Transition Lecture".freeze
    CAMPAIGN_DESCRIPTION = "Anmeldung".freeze
    PASSPHRASE = "geheim".freeze
    FLAGS = ["registration_campaigns", "roster_maintenance",
             "next_semester_banner"].freeze
    TUTORIALS = [["Tutorial Mo 14:00", 12],
                 ["Tutorial Di 16:00", 12],
                 ["Tutorial Fr 9:00", 8]].freeze

    def setup!
      ensure_non_production!
      require "factory_bot_rails"

      enable_flags!
      lecture = next_term_lecture!
      campaign = open_campaign!(lecture)

      output("Ready. Lecture ##{lecture.id} (#{lecture.title}), " \
             "passphrase: #{PASSPHRASE.inspect}, " \
             "campaign: #{campaign.description} (#{campaign.status})")
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def enable_flags!
        FLAGS.each do |flag|
          Flipper.add(flag) unless Flipper.exist?(flag)
          Flipper.enable(flag)
          output("flag enabled: #{flag}")
        end
      end

      def next_term!
        active = Term.active
        fail_setup!("No active term found. Run just seed first.") unless active

        active.next || FactoryBot.create(
          :term,
          season: active.season == "SS" ? "WS" : "SS",
          year: active.season == "SS" ? active.year : active.year + 1
        )
      end

      def next_term_lecture!
        term = next_term!
        course = Course.find_by(title: COURSE_TITLE) ||
                 FactoryBot.create(:course, title: COURSE_TITLE)
        lecture = Lecture.find_by(course: course, term: term) ||
                  FactoryBot.create(:lecture, course: course, term: term)
        lecture.update!(released: "all", passphrase: PASSPHRASE)
        lecture
      end

      def open_campaign!(lecture)
        campaign = Registration::Campaign.find_by(
          campaignable: lecture, description: CAMPAIGN_DESCRIPTION
        ) || FactoryBot.create(
          :registration_campaign,
          campaignable: lecture,
          status: :draft,
          allocation_mode: :first_come_first_served,
          registration_deadline: 2.weeks.from_now,
          description: CAMPAIGN_DESCRIPTION
        )

        TUTORIALS.each do |title, capacity|
          tutorial = Tutorial.find_by(lecture: lecture, title: title) ||
                     FactoryBot.create(:tutorial, lecture: lecture,
                                                  title: title,
                                                  capacity: capacity)
          tutorial.update!(capacity: capacity)
          next if Registration::Item.exists?(registration_campaign: campaign,
                                             registerable: tutorial)

          FactoryBot.create(:registration_item,
                            registration_campaign: campaign,
                            registerable: tutorial)
        end

        campaign.update!(status: :open) unless campaign.open?
        campaign
      end

      def output(message)
        $stdout.puts(message)
      end

      def fail_setup!(message)
        raise(message)
      end
  end
end
