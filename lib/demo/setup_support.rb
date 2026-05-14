require_relative "setup_support_assessment"

module Demo
  module SetupSupport
    extend self
    extend SetupSupportAssessment if defined?(SetupSupportAssessment)

    LEGACY_TASK_GROUPS = [
      ["solver:create_campaign", "solver:create_registrations"],
      [
        "solver:create_mixed_fcfs_campaign",
        "solver:create_mixed_fcfs_registrations"
      ],
      ["solver:create_two_stage_campaign"]
    ].freeze

    LECTURE_CAMPAIGN_DESCRIPTION = "Demo Lecture Roster Campaign".freeze
    SEMINAR_CAMPAIGN_DESCRIPTION = "Demo Seminar Roster Campaign".freeze
    SEMINAR_COURSE_TITLE = "Demo Roster Seminar".freeze
    ROSTER_ENABLED_FLAGS = ["roster_maintenance", "registration_campaigns"].freeze
    ROSTER_DISABLED_FLAGS = ["assessment_grading"].freeze
    LECTURE_TUTORIAL_CAPACITIES = [10, 8, 8, 6].freeze
    LECTURE_TUTORIAL_TITLES = [
      "Demo Tutorial 1",
      "Demo Tutorial 2",
      "Demo Tutorial 3",
      "Demo Tutorial 4"
    ].freeze
    SEMINAR_TALK_TITLES = (1..10).map { |i| "Demo Talk #{i}" }.freeze

    def verify!
      ensure_non_production!
      configure_feature_flags!(enabled: ROSTER_ENABLED_FLAGS)

      Rails.logger.debug("=== Demo Verification ===")
      LEGACY_TASK_GROUPS.each do |group|
        group.each do |task_name|
          Rails.logger.debug { "Running #{task_name}..." }
          invoke_task(task_name)
          Rails.logger.debug("")
        end
      end
      Rails.logger.debug("=== Demo Verification Complete ===")
    end

    def setup_rosters!
      ensure_non_production!
      configure_feature_flags!(
        enabled: ROSTER_ENABLED_FLAGS,
        disabled: ROSTER_DISABLED_FLAGS
      )

      Rails.logger.debug("=== Demo Roster Setup ===")
      with_quiet_logging do
        setup_lecture_rosters!
        setup_seminar_rosters!
      end
      Rails.logger.debug("=== Demo Roster Setup Complete ===")
    end

    def setup!
      setup_rosters!
      setup_assessment! if respond_to?(:setup_assessment!)
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def configure_feature_flags!(enabled:, disabled: [])
        Rails.logger.debug("Configuring feature flags...")
        with_quiet_logging do
          enabled.each do |flag|
            ensure_feature_exists!(flag)
            Flipper.enable(flag)
            Rails.logger.debug { "  ✓ enabled #{flag}" }
          end

          disabled.each do |flag|
            ensure_feature_exists!(flag)
            Flipper.disable(flag)
            Rails.logger.debug { "  ✓ disabled #{flag}" }
          end
        end
        Rails.logger.debug("")
      end

      def ensure_feature_exists!(flag)
        Flipper.add(flag)
      end

      def invoke_task(task_name)
        Rake::Task[task_name].invoke
      ensure
        Rake::Task[task_name].reenable
      end

      def lecture!
        lecture = Lecture.find_by(id: 1)
        # rubocop:disable Rails/Exit
        abort("Lecture 1 not found. Run just seed first.") unless lecture
        # rubocop:enable Rails/Exit

        teacher = teacher!
        lecture.update!(teacher: teacher) if lecture.teacher != teacher
        lecture
      end

      def teacher!
        teacher = User.find_by(email: "teacher@mampf.edu")
        # rubocop:disable Rails/Exit
        abort("User teacher@mampf.edu not found. Run just seed first.") unless teacher
        # rubocop:enable Rails/Exit

        teacher
      end

      def setup_lecture_rosters!
        lecture = lecture!
        reset_lecture_rosters!(lecture)

        tutorials = LECTURE_TUTORIAL_TITLES.zip(LECTURE_TUTORIAL_CAPACITIES)
                                           .map do |title, capacity|
          tutorial = Tutorial.find_or_initialize_by(lecture: lecture, title: title)
          tutorial.capacity = capacity
          tutorial.skip_campaigns = false if tutorial.respond_to?(:skip_campaigns=)
          tutorial.save!
          tutorial.tutorial_memberships.delete_all
          tutorial
        end

        campaign = recreate_campaign!(
          lecture,
          description: LECTURE_CAMPAIGN_DESCRIPTION,
          allocation_mode: :preference_based
        )

        tutorials.each { |tutorial| ensure_item!(campaign, tutorial) }

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
        reset_seminar_rosters!(seminar)

        talks = SEMINAR_TALK_TITLES.each_with_index.map do |title, index|
          talk = Talk.find_or_initialize_by(lecture: seminar, title: title)
          talk.capacity = 1
          talk.position ||= index + 1
          talk.skip_campaigns = false if talk.respond_to?(:skip_campaigns=)
          talk.save!
          talk.speaker_talk_joins.delete_all
          talk
        end

        campaign = recreate_campaign!(
          seminar,
          description: SEMINAR_CAMPAIGN_DESCRIPTION,
          allocation_mode: :preference_based
        )

        talks.each { |talk| ensure_item!(campaign, talk) }
        ensure_policy!(campaign)

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

      def seminar!
        teacher = teacher!
        course = Course.find_or_create_by!(title: SEMINAR_COURSE_TITLE) do |record|
          record.short_title = "DRS"
        end

        seminar = Lecture.find_by(course: course)
        seminar ||= FactoryBot.create(
          :seminar,
          course: course,
          teacher: teacher,
          released: true,
          term: Term.active || FactoryBot.create(:term)
        )

        seminar.update!(teacher: teacher) if seminar.teacher != teacher
        teacher.lectures << seminar unless teacher.lectures.exists?(seminar.id)
        seminar
      end

      def recreate_campaign!(campaignable, description:, allocation_mode:)
        destroy_campaign!(
          Registration::Campaign.find_by(campaignable: campaignable, description: description)
        )

        FactoryBot.create(
          :registration_campaign,
          campaignable: campaignable,
          status: :draft,
          allocation_mode: allocation_mode,
          registration_deadline: 1.week.from_now,
          description: description
        )
      end

      def destroy_campaign!(campaign)
        return unless campaign

        # rubocop:disable Rails/SkipsModelValidations
        campaign.update_columns(
          status: Registration::Campaign.statuses[:draft],
          updated_at: Time.current
        )
        # rubocop:enable Rails/SkipsModelValidations
        campaign.destroy!
      end

      def ensure_item!(campaign, registerable)
        Registration::Item.find_or_create_by!(
          registration_campaign: campaign,
          registerable: registerable
        )
      end

      def ensure_policy!(campaign)
        Registration::Policy.find_or_create_by!(
          registration_campaign: campaign,
          kind: :institutional_email,
          phase: :finalization
        ) do |policy|
          policy.active = true
          policy.config = { "allowed_domains" => "mampf.edu" }
        end
      end

      def build_users(prefix:, count:, domain:, name_prefix:)
        Array.new(count) do |i|
          email = "#{prefix}_#{i}@#{domain}"
          User.find_by(email: email) || FactoryBot.create(
            :confirmed_user,
            email: email,
            name: "#{name_prefix} #{i}"
          )
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

      def reset_lecture_rosters!(lecture)
        demo_tutorials(lecture).each do |tutorial|
          tutorial.tutorial_memberships.delete_all
        end

        destroy_campaign!(
          Registration::Campaign.find_by(
            campaignable: lecture,
            description: LECTURE_CAMPAIGN_DESCRIPTION
          )
        )
      end

      def reset_seminar_rosters!(seminar)
        Talk.where(lecture: seminar, title: SEMINAR_TALK_TITLES).find_each do |talk|
          talk.speaker_talk_joins.delete_all
        end

        destroy_campaign!(
          Registration::Campaign.find_by(
            campaignable: seminar,
            description: SEMINAR_CAMPAIGN_DESCRIPTION
          )
        )
      end

      def demo_tutorials(lecture)
        lecture.tutorials.where(title: LECTURE_TUTORIAL_TITLES)
      end

      def demo_tutorial_ids(lecture)
        demo_tutorials(lecture).pluck(:id)
      end

      def with_quiet_logging
        old_level = ActiveRecord::Base.logger&.level
        ActiveRecord::Base.logger&.level = :warn
        yield
      ensure
        ActiveRecord::Base.logger&.level = old_level
      end
  end
end
