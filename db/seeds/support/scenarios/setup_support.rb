module Scenarios
  module SetupSupport
    extend self
    extend Scenarios::AssessmentSetupSupport
    extend Scenarios::PerformanceSetupSupport
    extend Scenarios::EligibilitySetupSupport
    extend Scenarios::ExamSetupSupport
    extend Scenarios::GradingSetupSupport
    extend Scenarios::HomeworkSubmissionSupport

    LECTURE_CAMPAIGN_DESCRIPTION = "Demo Lecture Roster Campaign".freeze
    SEMINAR_CAMPAIGN_DESCRIPTION = "Demo Seminar Roster Campaign".freeze
    SEMINAR_COURSE_TITLE = "Demo Roster Seminar".freeze
    LECTURE_TUTORIAL_CAPACITIES = [10, 8, 8, 6].freeze
    LECTURE_TUTORIAL_TITLES = [
      "Demo Tutorial 1",
      "Demo Tutorial 2",
      "Demo Tutorial 3",
      "Demo Tutorial 4"
    ].freeze
    SEMINAR_TALK_TITLES = (1..10).map { |i| "Demo Talk #{i}" }.freeze

    def setup_campaigns!
      ensure_non_production!
      Scenarios::CampaignSetupSupport.setup!
    end

    def setup_rosters!
      ensure_non_production!

      Rails.logger.debug("=== Demo Roster Setup ===")
      Scenarios::QuietLoggingSupport.with_quiet_logging do
        setup_lecture_rosters!
        setup_seminar_rosters!
      end
      Rails.logger.debug("=== Demo Roster Setup Complete ===")
    end

    # `homework` seats the accounts a developer signs in with a few steps
    # later (Seeds::CourseworkSupport); homework staged before that would
    # leave them without a hand-in.
    def setup!(homework: true)
      ensure_non_production!
      setup_assessment!
      setup_homework_submissions! if homework
      setup_performance!
      setup_eligibility!
      setup_exams!
      setup_grading!
    end

    def setup_from_scratch!(homework: true)
      ensure_non_production!
      setup_rosters!
      setup!(homework: homework)
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def lecture!
        lecture = Scenarios::LectureSupport.find
        # rubocop:disable Rails/Exit
        abort(Scenarios::LectureSupport::MISSING_LECTURE_MESSAGE) unless lecture
        # rubocop:enable Rails/Exit

        teacher = teacher!
        lecture.update!(teacher: teacher) if lecture.teacher != teacher
        lecture
      end

      def teacher!
        teacher = Scenarios::LectureSupport.teacher
        # rubocop:disable Rails/Exit
        abort(Scenarios::LectureSupport::MISSING_TEACHER_MESSAGE) unless teacher
        # rubocop:enable Rails/Exit

        teacher
      end

      def setup_lecture_rosters!
        lecture = lecture!
        tutorials = LECTURE_TUTORIAL_TITLES.zip(LECTURE_TUTORIAL_CAPACITIES)
                                           .map do |title, capacity|
          Tutorial.create!(lecture: lecture, title: title, capacity: capacity)
        end

        campaign = create_campaign!(
          lecture,
          description: LECTURE_CAMPAIGN_DESCRIPTION,
          allocation_mode: :preference_based
        )

        tutorials.each { |tutorial| add_item!(campaign, tutorial) }

        users = build_users(
          prefix: "demo_lecture_student",
          count: LECTURE_TUTORIAL_CAPACITIES.sum,
          domain: "example.com",
          name_prefix: "Demo Lecture Student"
        )

        items = campaign.registration_items.includes(:registerable).to_a
        users.each do |user|
          create_ranked_preferences!(campaign, user, items.shuffle)
        end

        campaign.update!(status: :closed)
        Registration::AllocationService.new(campaign).allocate!
        campaign.finalize!

        memberships = TutorialMembership.where(tutorial_id: tutorials.map(&:id)).count
        Rails.logger.debug do
          "Lecture roster ready: #{memberships} tutorial memberships across 4 tutorials."
        end
        Rails.logger.debug("")
      end

      def setup_seminar_rosters!
        seminar = seminar!

        talks = SEMINAR_TALK_TITLES.each_with_index.map do |title, index|
          Talk.create!(lecture: seminar, title: title, capacity: 1, position: index + 1)
        end

        campaign = create_campaign!(
          seminar,
          description: SEMINAR_CAMPAIGN_DESCRIPTION,
          allocation_mode: :preference_based
        )

        talks.each { |talk| add_item!(campaign, talk) }
        add_policy!(campaign)

        valid_users = build_users(
          prefix: "demo_seminar_student",
          count: 12,
          domain: "mampf.edu",
          name_prefix: "Demo Seminar Student"
        )
        rejected_users = build_users(
          prefix: "demo_seminar_rejected",
          count: 2,
          domain: "example.com",
          name_prefix: "Demo Seminar Rejected"
        )

        items = campaign.registration_items.includes(:registerable).to_a
        (valid_users + rejected_users).each do |user|
          create_ranked_preferences!(campaign, user, items.shuffle)
        end

        campaign.update!(status: :closed)
        Registration::AllocationService.new(campaign).allocate!
        campaign.finalize!

        Rails.logger.debug do
          "Seminar roster ready: #{campaign.confirmed_count} allocated, " \
            "#{campaign.unassigned_users.count} unassigned, " \
            "#{campaign.rejected_users.count} rejected."
        end
        Rails.logger.debug("")
      end

      # Looked up rather than built once and passed around: setup_rosters! and
      # the assessment step both call this, each in a run of its own.
      def seminar!
        return @seminar if defined?(@seminar)

        teacher = teacher!
        course = Course.create!(title: SEMINAR_COURSE_TITLE, short_title: "DRS")
        @seminar = FactoryBot.create(:seminar, course: course, teacher: teacher,
                                               released: true, term: Term.active)
        teacher.lectures << @seminar
        @seminar
      end

      def create_campaign!(campaignable, description:, allocation_mode:)
        FactoryBot.create(
          :registration_campaign,
          campaignable: campaignable,
          status: :draft,
          allocation_mode: allocation_mode,
          registration_deadline: 1.week.from_now,
          description: description
        )
      end

      def add_item!(campaign, registerable)
        Registration::Item.create!(registration_campaign: campaign, registerable: registerable)
      end

      def add_policy!(campaign)
        Registration::Policy.create!(
          registration_campaign: campaign,
          kind: :institutional_email,
          phase: :finalization,
          active: true,
          config: { "allowed_domains" => "mampf.edu" }
        )
      end

      def build_users(prefix:, count:, domain:, name_prefix:)
        Array.new(count) do |i|
          FactoryBot.create(:confirmed_user, email: "#{prefix}_#{i}@#{domain}",
                                             name: "#{name_prefix} #{i}")
        end
      end

      def create_ranked_preferences!(campaign, user, items)
        items.each_with_index do |item, index|
          Registration::UserRegistration.create!(
            user: user,
            registration_campaign: campaign,
            registration_item: item,
            preference_rank: index + 1,
            status: :pending
          )
        end
      end

      def demo_tutorials(lecture)
        lecture.tutorials.where(title: LECTURE_TUTORIAL_TITLES)
      end

      def demo_tutorial_ids(lecture)
        demo_tutorials(lecture).pluck(:id)
      end

      # Every group that has anybody in it, the seed's own included: the named
      # accounts one signs in with sit in those, and homework that is graded
      # should reach them too.
      def staffed_tutorials(lecture)
        lecture.tutorials.order(:title).select { |tutorial| tutorial.tutorial_memberships.any? }
      end

      def staffed_tutorial_ids(lecture)
        staffed_tutorials(lecture).map(&:id)
      end
  end
end
