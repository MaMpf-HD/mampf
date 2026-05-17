module Demo
  module SetupSupport
    extend self
    extend Demo::AssessmentSetupSupport

    LECTURE_CAMPAIGN_DESCRIPTION = "Demo Lecture Roster Campaign".freeze
    SEMINAR_CAMPAIGN_DESCRIPTION = "Demo Seminar Roster Campaign".freeze
    SEMINAR_COURSE_TITLE = "Demo Roster Seminar".freeze
    ROSTER_ENABLED_FLAGS = ["roster_maintenance", "registration_campaigns"].freeze
    ROSTER_DISABLED_FLAGS = ["assessment_grading"].freeze
    ASSESSMENT_ENABLED_FLAGS = ["assessment_grading"].freeze
    ASSESSMENT_DISABLED_FLAGS = ["student_performance"].freeze
    PERFORMANCE_ENABLED_FLAGS = ["assessment_grading", "student_performance"].freeze
    LECTURE_TUTORIAL_CAPACITIES = [10, 8, 8, 6].freeze
    LECTURE_TUTORIAL_TITLES = [
      "Demo Tutorial 1",
      "Demo Tutorial 2",
      "Demo Tutorial 3",
      "Demo Tutorial 4"
    ].freeze
    SEMINAR_TALK_TITLES = (1..10).map { |i| "Demo Talk #{i}" }.freeze
    DEMO_ACHIEVEMENT_ATTRIBUTES = [
      { title: "Blackboard Talk", value_type: :boolean, threshold: nil },
      { title: "Homework Points", value_type: :numeric, threshold: 15 },
      { title: "Attendance Rate", value_type: :percentage, threshold: 80.0 }
    ].freeze

    def setup_flags!
      ensure_non_production!
      configure_feature_flags!(
        enabled: (ROSTER_ENABLED_FLAGS + PERFORMANCE_ENABLED_FLAGS).uniq
      )
    end

    def setup_campaigns!
      Demo::CampaignSetupSupport.setup!
    end

    def setup_rosters!
      setup_flags!

      Rails.logger.debug("=== Demo Roster Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        setup_lecture_rosters!
        setup_seminar_rosters!
      end
      Rails.logger.debug("=== Demo Roster Setup Complete ===")
    end

    def setup!
      setup_rosters!
      setup_assessment!
      setup_performance!
    end

    def setup_performance!
      setup_flags!

      lecture = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        lecture = performance_lecture!
      end

      Rails.logger.debug("=== Demo Performance Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
        reset_demo_performance!(lecture)
        create_demo_achievements!(lecture)
        seed_demo_achievement_grades!(lecture)
        compute_demo_performance_records!(lecture)
        print_performance_summary(lecture)
      end
      Rails.logger.debug("=== Demo Performance Setup Complete ===")
    end

    def performance_lecture!
      lecture = assessment_lecture!
      return lecture if demo_assignments(lecture).exists?

      # rubocop:disable Rails/Exit
      abort("Lecture 1 has no demo assignments. Run demo:assessment first.")
      # rubocop:enable Rails/Exit
    end

    private

      # rubocop:disable Rails/Exit
      def ensure_non_production!
        abort("Cannot run in production!") if Rails.env.production?
      end
      # rubocop:enable Rails/Exit

      def configure_feature_flags!(enabled:, disabled: [])
        messages = []

        Rails.logger.debug("Configuring feature flags...")
        Demo::QuietLoggingSupport.with_quiet_logging do
          enabled.each do |flag|
            feature = ensure_feature_exists!(flag)
            feature.enable
            messages << "  enabled #{flag}"
          end

          disabled.each do |flag|
            feature = ensure_feature_exists!(flag)
            feature.disable
            messages << "  disabled #{flag}"
          end
        end

        messages.each do |message|
          Rails.logger.debug(message)
        end
        Rails.logger.debug("")
      end

      def ensure_feature_exists!(flag)
        feature_name = flag.to_s
        Flipper::Adapters::ActiveRecord::Feature.find_or_create_by!(key: feature_name)
        Flipper[feature_name]
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

      def demo_achievement_titles
        DEMO_ACHIEVEMENT_ATTRIBUTES.pluck(:title)
      end

      def demo_achievements(lecture)
        lecture.achievements.where(title: demo_achievement_titles).order(:title)
      end

      def reset_demo_performance!(lecture)
        lecture.student_performance_records.delete_all

        demo_achievements(lecture).find_each(&:destroy!)

        Rails.logger.debug("Reset demo achievements and performance records.")
      end

      def create_demo_achievements!(lecture)
        memberships = TutorialMembership.where(tutorial_id: demo_tutorial_ids(lecture))
                                        .pluck(:user_id, :tutorial_id)

        DEMO_ACHIEVEMENT_ATTRIBUTES.each do |attrs|
          achievement = lecture.achievements.create!(attrs)
          achievement.ensure_assessment!(
            requires_points: false,
            requires_submission: false
          )

          assessment = achievement.assessment
          assessment.assessment_participations.delete_all
          memberships.each do |user_id, tutorial_id|
            assessment.assessment_participations.create!(
              user_id: user_id,
              tutorial_id: tutorial_id,
              status: :reviewed
            )
          end
        end

        Rails.logger.debug { "Created #{DEMO_ACHIEVEMENT_ATTRIBUTES.count} demo achievements." }
      end

      def seed_demo_achievement_grades!(lecture)
        demo_achievements(lecture).each do |achievement|
          assessment = achievement.assessment
          next unless assessment

          seeded = 0
          skipped = 0

          assessment.assessment_participations.find_each do |participation|
            if rand < 0.1
              skipped += 1
              next
            end

            participation.update!(
              grade_text: demo_achievement_grade_text(
                achievement,
                student_quality(participation.user_id)
              )
            )
            seeded += 1
          end

          Rails.logger.debug do
            "Seeded #{achievement.title}: #{seeded} graded, #{skipped} ungraded."
          end
        end
      end

      def compute_demo_performance_records!(lecture)
        user_ids = TutorialMembership.where(tutorial_id: demo_tutorial_ids(lecture))
                                     .distinct
                                     .pluck(:user_id)
        service = StudentPerformance::ComputationService.new(lecture: lecture)

        User.where(id: user_ids).find_each do |user|
          service.compute_and_upsert_record_for(user)
        end

        Rails.logger.debug { "Computed #{user_ids.count} demo performance records." }
      end

      def print_performance_summary(lecture)
        Rails.logger.debug("Performance Summary")

        demo_achievements(lecture).each do |achievement|
          participations = achievement.assessment.assessment_participations
          graded = participations.where.not(grade_text: [nil, ""]).count
          ungraded = participations.where(grade_text: [nil, ""]).count

          Rails.logger.debug { "#{achievement.title}: #{graded} graded, #{ungraded} ungraded" }
        end

        Rails.logger.debug { "Records: #{lecture.student_performance_records.count}" }
        Rails.logger.debug("")
      end

      def demo_achievement_grade_text(achievement, quality)
        case achievement.value_type.to_s
        when "boolean"
          quality > 0.5 ? "pass" : "fail"
        when "numeric"
          max = (achievement.threshold * 1.5).ceil
          (quality * max).round.to_s
        when "percentage"
          (quality * 100).round(1).to_s
        end
      end
  end
end
