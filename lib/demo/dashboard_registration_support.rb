module Demo
  # Gives students 1-4 a different registration state (pending, confirmed,
  # rejected, rejected + bookmarked) so the dashboard's bands all have
  # something to show; student5 stays plain-bookmarked, and a fifth lecture
  # stays open and unapplied-for, to show the search's "Registration open"
  # badge. student2 also gets a second lecture with two campaigns in
  # conflicting states, to demonstrate Registration::StatusQuery precedence.
  module DashboardRegistrationSupport
    extend self

    STUDENT_EMAILS = (1..5).map { |i| "student#{i}@mampf.edu" }.freeze

    def setup!
      ensure_non_production!

      student1, student2, student3, student4, student5 = students!

      setup_pending!(student1)
      setup_confirmed_not_rostered!(student2)
      setup_rejected!(student3)
      setup_rejected_and_bookmarked!(student4)
      setup_plain_bookmark!(student5)
      setup_open_unapplied!
      setup_pending_overrides_older_rejection!(student2)
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end

      def students!
        STUDENT_EMAILS.map do |email|
          user = User.find_by(email: email)
          abort("User #{email} not found. Run just seed first.") unless user

          user
        end
      end

      def teacher!
        teacher = User.find_by(email: "teacher@mampf.edu")
        abort("User teacher@mampf.edu not found. Run just seed first.") unless teacher

        teacher
      end
      # rubocop:enable Rails/Exit

      # Pending, no roster seat yet. Must be preference_based, since FCFS
      # decides synchronously and never leaves a row pending. Next term,
      # since an :open campaign would not survive in the current one.
      def setup_pending!(student)
        lecture = lecture_for("Einführung in die Numerik", next_term)
        campaign = reset_campaign!(lecture, :preference_based, :open)

        create_registration!(student, campaign, :pending, preference_rank: 1)
      end

      # Confirmed, not yet rostered - confirming does not by itself create a
      # LectureMembership. Next term, same reason as setup_pending! above.
      def setup_confirmed_not_rostered!(student)
        lecture = lecture_for("Maßtheorie und Wahrscheinlichkeit", next_term)
        campaign = reset_campaign!(lecture, :first_come_first_served, :open)

        create_registration!(student, campaign, :confirmed)
      end

      # Rejected, not dismissed. :completed (not :closed) so the campaign
      # survives the seed's cleanup; :policy_rejected so the lecture's home
      # tab can explain why.
      def setup_rejected!(student)
        lecture = lecture_for("Algebraische Topologie", current_term)
        campaign = reset_campaign!(lecture, :first_come_first_served, :completed)

        create_registration!(student, campaign, :policy_rejected)
      end

      # Same as above, plus a separate bookmark - registration status takes
      # precedence, so it still shows only once.
      def setup_rejected_and_bookmarked!(student)
        lecture = lecture_for("Funktionalanalysis", current_term)
        campaign = reset_campaign!(lecture, :first_come_first_served, :completed)

        create_registration!(student, campaign, :policy_rejected)
        bookmark!(student, lecture)
      end

      # Plain bookmark, no registration campaign at all.
      def setup_plain_bookmark!(student)
        lecture = lecture_for("Diskrete Mathematik", current_term)
        bookmark!(student, lecture)
      end

      # Open, nobody applied yet - only discoverable via search's
      # "Registration open" badge, not shown on any dashboard.
      def setup_open_unapplied!
        lecture = lecture_for("Partielle Differentialgleichungen", next_term)
        reset_campaign!(lecture, :first_come_first_served, :open)
      end

      # A second lecture for student2: an older rejected campaign
      # (:completed) plus a later reapplication still awaiting a decision
      # (:closed). Registration::StatusQuery's precedence means the
      # dashboard must show "Pending" here, not "Rejected" - see
      # status_query_spec.rb. Next term, same reason as setup_pending!.
      def setup_pending_overrides_older_rejection!(student)
        lecture = lecture_for("Algebra und Zahlentheorie", next_term)
        Demo::CampaignCleanup.discard_all!(lecture)

        rejected_campaign = FactoryBot.create(:registration_campaign, :completed,
                                              campaignable: lecture,
                                              allocation_mode: :first_come_first_served)
        create_registration!(student, rejected_campaign, :policy_rejected)

        pending_campaign = FactoryBot.create(:registration_campaign, :closed,
                                             campaignable: lecture,
                                             allocation_mode: :preference_based)
        create_registration!(student, pending_campaign, :pending, preference_rank: 1)
      end

      def current_term
        Demo::TermSupport.active_term
      end

      def next_term
        Demo::TermSupport.next_term
      end

      def lecture_for(course_title, term)
        Demo::TermSupport.find_or_create_lecture!(
          term: term, teacher: teacher!,
          course_title: course_title, short_title: course_title.first(12)
        )
      end

      def bookmark!(student, lecture)
        return if student.lectures.include?(lecture)

        student.subscribe_lecture!(lecture)
      end

      # Rebuilt from scratch on every build, like the other demo scenarios:
      # a registration campaign cannot be rewound once a student is in it.
      def reset_campaign!(lecture, allocation_mode, status)
        Demo::CampaignCleanup.discard!(Registration::Campaign.find_by(campaignable: lecture))

        FactoryBot.create(:registration_campaign, status,
                          campaignable: lecture, allocation_mode: allocation_mode)
      end

      def create_registration!(student, campaign, trait, preference_rank: nil)
        FactoryBot.create(:registration_user_registration, trait,
                          user: student,
                          registration_campaign: campaign,
                          registration_item: campaign.registration_items.first,
                          preference_rank: preference_rank)
      end
  end
end
