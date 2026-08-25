module Seeds
  # Rebuilds the development seed data that ships in mampf-init-data.
  #
  # The set is meant to look the same every year: everything moves one year
  # forward, so the term that was current stays current, and the demo material
  # is baked in rather than left to a task nobody remembers to run.
  module BuildSupport
    extend self

    PASSWORD = "zitrone-diskette-vorhang-42".freeze
    # Two accounts keep an outdated password policy so that the forced password
    # change can be tried out; everyone else gets in without the detour.
    STALE_PASSWORD_ACCOUNTS = ["student5@mampf.edu", "moded@mampf.edu"].freeze
    ENROLMENT_DESCRIPTION = "Anmeldung zur Veranstaltung".freeze
    TUTORIAL_DESCRIPTION = "Anmeldung zu den Übungsgruppen".freeze
    TALK_DESCRIPTION = "Vergabe der Vortragsthemen".freeze

    # One transaction, so a build that fails halfway can be retried on the same
    # dump instead of one that is already a year ahead.
    def build!
      ensure_development!
      require "factory_bot_rails"

      ActiveRecord::Base.transaction do
        advance_one_year!
        Demo::SetupSupport.setup!
        Demo::CampaignSetupSupport.setup!
        add_running_campaigns!
        extend_open_deadlines!
        Seeds::EnrichSupport.enrich!
        # last, so that the accounts the demo scenarios create are usable too
        reset_passwords!
        stage_password_policy!
      end
      report!
    end

    # Moves the whole data set one year forward, terms and the dates that hang
    # off them alike, so that the current term stays current.
    def advance_one_year!
      ensure_development!
      # rubocop:disable Rails/SkipsModelValidations
      Term.update_all("year = year + 1")
      Term.update_all(shift(:submission_deletion_mail, :submission_deletion_reminder,
                            :submissions_deleted_at))
      Assignment.update_all(shift(:deadline, :deletion_date))
      Lesson.update_all(shift(:date))
      Medium.update_all(shift(:released_at, :file_last_edited))
      Submission.update_all(shift(:last_modification_by_users_at))
      Voucher.update_all(shift(:expires_at, :invalidated_at))
      # rubocop:enable Rails/SkipsModelValidations
    end

    # Every account gets the same documented password, long and strong enough
    # for the password policy, and starts out unlocked.
    def reset_passwords!
      ensure_development!

      User.find_each do |user|
        user.password = PASSWORD
        user.password_confirmation = PASSWORD
        user.failed_attempts = 0
        user.locked_at = nil
        user.unlock_token = nil
        user.save!
      end
    end

    # Registration campaigns that are open right now, in the current term and
    # in the one after it, for a lecture and for a seminar each.
    def add_running_campaigns!
      ensure_development!

      [current_term, next_term].each do |term|
        open_campaign!(lecture_for(term), TUTORIAL_DESCRIPTION, items_count: 4,
                                                                capacity: 12)
        open_campaign!(seminar_for(term), TALK_DESCRIPTION, items_count: 8)
      end
    end

    # Setting a password marks the account as following the current policy, so
    # the two demo accounts are put back afterwards. No-op until the columns
    # exist (PR #1141).
    def stage_password_policy!
      ensure_development!
      return unless User.column_names.include?("password_policy_version")

      # rubocop:disable Rails/SkipsModelValidations
      User.where(email: STALE_PASSWORD_ACCOUNTS)
          .update_all(password_policy_version: 0, password_changed_at: nil)
      # rubocop:enable Rails/SkipsModelValidations
    end

    # The demo scenarios set their deadlines a week out, which is useless in a
    # dump someone restores months later.
    def extend_open_deadlines!
      ensure_development!
      # rubocop:disable Rails/SkipsModelValidations
      Registration::Campaign.open.update_all(registration_deadline: 1.year.from_now)
      # rubocop:enable Rails/SkipsModelValidations
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_development!
        return if Rails.env.development?

        abort("This rebuilds the development dump: refusing to run in #{Rails.env}.")
      end
      # rubocop:enable Rails/Exit

      def shift(*columns)
        columns.map { |c| "#{c} = #{c} + interval '1 year'" }.join(", ")
      end

      def current_term
        Term.active || Term.order(:year, :season).last
      end

      def next_term
        term = current_term
        year, season = if term.season == "SS"
          [term.year, "WS"]
        else
          [term.year + 1, "SS"]
        end
        Term.find_or_create_by!(year: year, season: season)
      end

      def teacher
        @teacher ||= User.find_by(email: "teacher@mampf.edu") || User.find(2)
      end

      def lecture_for(term)
        find_or_create_lecture!(term, "lecture", "Analysis #{label(term)}",
                                "Ana #{label(term)}")
      end

      def seminar_for(term)
        find_or_create_lecture!(term, "seminar", "Seminar #{label(term)}",
                                "Sem #{label(term)}")
      end

      def label(term)
        "#{term.season} #{term.year}"
      end

      def find_or_create_lecture!(term, sort, course_title, short_title)
        course = Course.find_or_create_by!(title: course_title) do |c|
          c.short_title = short_title
        end
        Lecture.find_by(course: course, term: term) ||
          FactoryBot.create(:lecture, :released_for_all,
                            course: course, term: term, teacher: teacher,
                            sort: sort, locale: "en")
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

      def report!
        Rails.logger.debug do
          "Seed build done: term #{current_term.season} #{current_term.year}, " \
            "#{Lecture.count} lectures, #{User.count} users, " \
            "#{Registration::Campaign.open.count} open campaigns, " \
            "#{Announcement.count} announcements"
        end
      end
  end
end
