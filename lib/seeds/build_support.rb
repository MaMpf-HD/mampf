module Seeds
  # Rebuilds the development seed data that ships in mampf-init-data.
  #
  # The set is meant to stay usable: it moves forward to the term it should
  # play in, one semester on by default, and the demo material is baked in
  # rather than left to a task nobody remembers to run.
  module BuildSupport
    extend self

    PASSWORD = "lemon-floppy-curtain-42".freeze
    # Two accounts keep an outdated password policy so that the forced password
    # change can be tried out; everyone else gets in without the detour.
    STALE_PASSWORD_ACCOUNTS = ["student5@mampf.edu", "moded@mampf.edu"].freeze
    ENROLMENT_DESCRIPTION = "Anmeldung zur Veranstaltung".freeze
    TUTORIAL_DESCRIPTION = "Anmeldung zu den Übungsgruppen".freeze
    TALK_DESCRIPTION = "Vergabe der Vortragsthemen".freeze

    # One transaction, so a build that fails halfway can be retried on the same
    # dump instead of one that has already moved.
    def build!(target_term: nil)
      ensure_development!
      require "factory_bot_rails"
      semesters = semesters_until(target_term)

      ActiveRecord::Base.transaction do
        advance!(semesters)
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

    # A semester is half a year, so terms and the dates that hang off them move
    # by the same number of six-month steps and stay in step with each other.
    def advance!(semesters)
      ensure_development!
      months = 6 * Integer(semesters)
      # rubocop:disable Rails/SkipsModelValidations
      Term.update_all(rename_terms(semesters))
      Term.update_all(shift(months, :submission_deletion_mail,
                            :submission_deletion_reminder, :submissions_deleted_at))
      Assignment.update_all(shift(months, :deadline, :deletion_date))
      Lesson.update_all(shift(months, :date))
      Medium.update_all(shift(months, :released_at, :file_last_edited))
      Submission.update_all(shift(months, :last_modification_by_users_at))
      Voucher.update_all(shift(months, :expires_at, :invalidated_at))
      # rubocop:enable Rails/SkipsModelValidations
    end

    # The password ships with the dump, so it has to pass the policy. A lock
    # carried over from the source would keep a demo account out.
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

    def add_running_campaigns!
      ensure_development!

      [current_term, next_term].each do |term|
        open_campaign!(lecture_for(term), TUTORIAL_DESCRIPTION, items_count: 4,
                                                                capacity: 12)
        open_campaign!(seminar_for(term), TALK_DESCRIPTION, items_count: 8)
      end
    end

    # Setting a password marks the account as following the current policy, so
    # the two demo accounts are put back afterwards.
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

      def shift(months, *columns)
        columns.map { |c| "#{c} = #{c} + interval '#{months} months'" }.join(", ")
      end

      # Terms are counted in half years, so that WS follows SS within a year.
      def rename_terms(semesters)
        moved = "(#{term_index_sql} + #{Integer(semesters)})"
        "year = #{moved} / 2, " \
          "season = CASE #{moved} % 2 WHEN 0 THEN 'SS' ELSE 'WS' END"
      end

      def term_index_sql
        "year * 2 + CASE season WHEN 'SS' THEN 0 ELSE 1 END"
      end

      def term_index(term)
        (term.year * 2) + (term.season == "SS" ? 0 : 1)
      end

      # rubocop:disable Rails/Exit
      # Without a target the set moves on by a single semester, which is what
      # the next edition of the seed data usually is.
      def semesters_until(target_term)
        return 1 if target_term.blank?

        season, year = parse_term(target_term)
        steps = ((year * 2) + (season == "SS" ? 0 : 1)) - term_index(current_term)
        return steps if steps.positive?

        abort("The seed data is in #{label(current_term)}; " \
              "#{season} #{year} is not ahead of it.")
      end

      def parse_term(target_term)
        match = target_term.to_s.strip.match(/\A(SS|WS)\s*(\d{4})/i)
        abort("Give the target term as \"SS 2027\" or \"WS 2027\".") unless match

        [match[1].upcase, Integer(match[2])]
      end
      # rubocop:enable Rails/Exit

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
