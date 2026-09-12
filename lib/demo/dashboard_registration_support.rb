module Demo
  # Gives four of the five seeded students (student1..student5@mampf.edu) a
  # different registration state on a lecture of their own, so the
  # dashboard's pending/confirmed/rejected/bookmarked bands all have
  # something to show without waiting for a real campaign to reach that
  # state. The fifth lecture stays unapplied-for, to show what "Registration
  # open" looks like in search. student2 additionally gets a second lecture
  # with two campaigns in conflicting states, to demonstrate the
  # confirmed > pending > open > rejected precedence across campaigns (see
  # Registration::StatusQuery).
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

      # Pending registration, no roster seat yet. The campaign must be
      # preference_based, not the default first-come-first-served: FCFS
      # decides synchronously, so a pending FCFS row is not a state the
      # app's own UI ever produces or has anything to show for.
      #
      # Placed in the next term, like add_running_campaigns!: a campaign that
      # is still :open (not :completed) in the term the seed plays in is
      # exactly what settle_current_term_campaigns! discards afterwards.
      def setup_pending!(student)
        lecture = lecture_for("Einführung in die Numerik", next_term)
        campaign = reset_campaign!(lecture, :preference_based, :open)

        create_registration!(student, campaign, :pending, preference_rank: 1)
      end

      # Confirmed registration, not yet rostered - confirming an applicant
      # does not by itself create a LectureMembership, rostering is a
      # separate step. Also placed in the next term, for the same reason as
      # setup_pending! above: an :open campaign does not survive in the
      # current one.
      def setup_confirmed_not_rostered!(student)
        lecture = lecture_for("Maßtheorie und Wahrscheinlichkeit", next_term)
        campaign = reset_campaign!(lecture, :first_come_first_served, :open)

        create_registration!(student, campaign, :confirmed)
      end

      # Rejected registration, not dismissed. The campaign must be
      # :completed, not just :closed, and the trait must be :policy_rejected,
      # not :capacity_rejected, for the lecture's own home tab to explain why.
      # :completed survives settle_current_term_campaigns!, so this can sit
      # in the current term, like a real rejection would by now.
      def setup_rejected!(student)
        lecture = lecture_for("Algebraische Topologie", current_term)
        campaign = reset_campaign!(lecture, :first_come_first_served, :completed)

        create_registration!(student, campaign, :policy_rejected)
      end

      # Same as above, but the student separately bookmarked the lecture too -
      # still shown once in "You are registered for these", registration
      # status takes precedence over a plain bookmark.
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

      # Registration open, nobody has applied yet - not shown on any
      # dashboard, only discoverable via lecture search, where it carries
      # the "Registration open" badge. Next term, for the same reason as
      # setup_pending! above.
      def setup_open_unapplied!
        lecture = lecture_for("Partielle Differentialgleichungen", next_term)
        reset_campaign!(lecture, :first_come_first_served, :open)
      end

      # A second lecture for student2, with two campaigns: an older one the
      # student was rejected from (:completed), and a later reapplication
      # still awaiting a decision (:closed, a preference-based campaign
      # whose deadline passed but that the teacher has not finalized yet).
      # Placed in the next term, like setup_pending! above:
      # settle_current_term_campaigns! discards any campaign that is not
      # :completed on a lecture in the *current* term on every rebuild, and
      # would otherwise wipe out the :closed one here.
      # Registration::StatusQuery pools registrations across all of a
      # lecture's campaigns and applies one precedence order
      # (confirmed > pending > open > rejected), so the dashboard must show
      # "Pending" here, not "Rejected" - see status_query_spec.rb and
      # e2e/dashboard.spec.ts for the precedence rules this demonstrates.
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
