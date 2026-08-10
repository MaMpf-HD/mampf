module Demo
  # Sets up everything needed to observe the next-term banner feature:
  # enables the relevant feature flags, makes sure a next term exists, and
  # creates demo lectures in it covering the states a student can encounter:
  # - published with an open registration campaign ("Registration open"
  #   badge in the search, registerable from the lecture page)
  # - published without a campaign (subscribe-only)
  # - unpublished (must NOT count towards the banner and must not appear
  #   in the student search)
  module NextTermBannerSupport
    extend self

    LECTURES = [
      { title: "Demo Next Term (with registration)", published: true,
        campaign: true },
      { title: "Demo Next Term (subscribe only)", published: true,
        campaign: false },
      { title: "Demo Next Term (unpublished)", published: false,
        campaign: false }
    ].freeze
    CAMPAIGN_DESCRIPTION = "Anmeldung".freeze
    TUTORIALS = [["Tutorial Mo 14:00", 12], ["Tutorial Fr 9:00", 8]].freeze

    def setup!
      ensure_non_production!

      # roster_maintenance + registration_campaigns, reused from the
      # existing demo bundle
      Demo::SetupSupport.setup_flags!
      enable_banner_flag!

      term = next_term!
      LECTURES.each { |config| ensure_lecture!(term, config) }

      output("Ready. Next term: #{term.to_label}. Visit the start page as " \
             "a student to see the banner (count: " \
             "#{Lecture.published.where(term: term).count} published).")
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def enable_banner_flag!
        Flipper.add("next_term_banner") unless Flipper.exist?("next_term_banner")
        Flipper.enable("next_term_banner")
        output("flag enabled: next_term_banner")
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

      def ensure_lecture!(term, config)
        course = Course.find_by(title: config[:title]) ||
                 FactoryBot.create(:course, title: config[:title])
        lecture = Lecture.find_by(course: course, term: term) ||
                  FactoryBot.create(:lecture, course: course, term: term)
        lecture.update!(released: config[:published] ? "all" : nil)
        open_campaign!(lecture) if config[:campaign]
        output("lecture ##{lecture.id}: #{config[:title]} " \
               "(#{config[:published] ? "published" : "unpublished"}" \
               "#{", campaign open" if config[:campaign]})")
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
