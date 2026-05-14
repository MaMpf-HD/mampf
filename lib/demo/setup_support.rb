module Demo
  module SetupSupport
    extend self

    LEGACY_SOLVER_TASK_GROUPS = [
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
    ASSESSMENT_ENABLED_FLAGS = ["assessment_grading"].freeze
    LECTURE_TUTORIAL_CAPACITIES = [10, 8, 8, 6].freeze
    LECTURE_TUTORIAL_TITLES = [
      "Demo Tutorial 1",
      "Demo Tutorial 2",
      "Demo Tutorial 3",
      "Demo Tutorial 4"
    ].freeze
    SEMINAR_TALK_TITLES = (1..10).map { |i| "Demo Talk #{i}" }.freeze

    def set_relevant_feature_flags!
      ensure_non_production!
      configure_feature_flags!(
        enabled: ROSTER_ENABLED_FLAGS + ASSESSMENT_ENABLED_FLAGS
      )
    end

    def setup_legacy_solver_playground!
      set_relevant_feature_flags!

      Rails.logger.debug("=== Legacy Solver Playground Setup ===")
      LEGACY_SOLVER_TASK_GROUPS.each do |group|
        group.each do |task_name|
          Rails.logger.debug { "Running #{task_name}..." }
          invoke_task(task_name)
          Rails.logger.debug("")
        end
      end
      Rails.logger.debug("=== Legacy Solver Playground Setup Complete ===")
    end

    def verify!
      setup_legacy_solver_playground!
    end

    def setup_rosters!
      set_relevant_feature_flags!

      Rails.logger.debug("=== Demo Roster Setup ===")
      with_quiet_logging do
        setup_lecture_rosters!
        setup_seminar_rosters!
      end
      Rails.logger.debug("=== Demo Roster Setup Complete ===")
    end

    def setup!
      setup_rosters!
      setup_assessment!
    end

    def setup_assessment!
      ensure_non_production!
      configure_feature_flags!(enabled: ASSESSMENT_ENABLED_FLAGS)

      lecture = nil
      with_quiet_logging do
        lecture = assessment_lecture!
      end

      Rails.logger.debug("=== Demo Assessment Setup ===")
      with_quiet_logging do
        reset_demo_assignments!(lecture)
        create_demo_assignments!(lecture)
        create_demo_tasks!(lecture)
        seed_demo_participations!(lecture)
        randomize_demo_statuses!(lecture)
        seed_demo_task_points!(lecture)
        seed_demo_talk_grades!
        print_assessment_summary(lecture)
      end
      Rails.logger.debug("=== Demo Assessment Setup Complete ===")
    end

    def assessment_lecture!
      lecture = lecture!
      return lecture if TutorialMembership.exists?(tutorial_id: demo_tutorial_ids(lecture))

      abort("Lecture 1 has no tutorial roster. Run demo:rosters first.")
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
        with_quiet_logging do
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

      def demo_assignment_attributes
        (1..10).map do |i|
          deadline = i < 10 ? (10 - i).weeks.ago : 3.days.ago
          { title: "Homework #{i}", deadline: deadline }
        end
      end

      def demo_assignment_titles
        demo_assignment_attributes.pluck(:title)
      end

      def demo_assignments(lecture)
        lecture.assignments.where(title: demo_assignment_titles).order(:deadline)
      end

      def reset_demo_assignments!(lecture)
        destroyed = 0

        demo_assignment_titles.each do |title|
          assignment = lecture.assignments.find_by(title: title)
          next unless assignment

          if assignment.assessment
            participation_ids = assignment.assessment.assessment_participations.select(:id)
            Assessment::TaskPoint.where(
              assessment_participation_id: participation_ids
            ).delete_all
            assignment.assessment.assessment_participations.delete_all
            assignment.assessment.tasks.delete_all
          end

          assignment.destroy!
          destroyed += 1
        end

        Rails.logger.debug { "Reset #{destroyed} demo assignments." }
      end

      def create_demo_assignments!(lecture)
        created = 0

        demo_assignment_attributes.each do |attrs|
          assignment = lecture.assignments.create!(
            title: attrs[:title],
            deadline: 1.year.from_now,
            accepted_file_type: ".pdf"
          )
          assignment.update_column(:deadline, attrs[:deadline])
          created += 1
        end

        Rails.logger.debug { "Created #{created} demo assignments for #{lecture.title}." }
      end

      def create_demo_tasks!(lecture)
        demo_assignments(lecture).each do |assignment|
          assessment = assignment.assessment
          next unless assessment&.requires_points?

          rand(4..5).times do |index|
            assessment.tasks.create!(
              description: "Problem #{index + 1}",
              max_points: 4,
              position: index + 1
            )
          end
        end

        Rails.logger.debug do
          "Created tasks for #{demo_assignments(lecture).count} demo assignments."
        end
      end

      def seed_demo_participations!(lecture)
        memberships = TutorialMembership.where(tutorial_id: demo_tutorial_ids(lecture))

        demo_assignments(lecture).each do |assignment|
          assessment = assignment.assessment
          next unless assessment

          memberships.find_each do |membership|
            assessment.assessment_participations.create!(
              user_id: membership.user_id,
              tutorial_id: membership.tutorial_id,
              status: :pending,
              submitted_at: assignment.deadline - rand(1..72).hours
            )
          end
        end

        Rails.logger.debug("Seeded participations from lecture 1 tutorial memberships.")
      end

      def randomize_demo_statuses!(lecture)
        assignments = demo_assignments(lecture).to_a
        assessment_ids = assignments.filter_map { |assignment| assignment.assessment&.id }
        dropout_cutoffs = {}

        demo_tutorials(lecture).each do |tutorial|
          participations = Assessment::Participation
                           .where(tutorial_id: tutorial.id, assessment_id: assessment_ids)
                           .includes(assessment: :assessable)
          next if participations.empty?

          participations.each do |participation|
            assessable = participation.assessment.assessable
            future_deadline = assessable.respond_to?(:deadline) &&
                              assessable.deadline&.future?
            recent_deadline = !future_deadline &&
                              assessable.respond_to?(:deadline) &&
                              assessable.deadline &&
                              assessable.deadline > 1.week.ago
            profile = student_profile(participation.user_id)

            if profile == :dropout
              cutoff = dropout_cutoffs[participation.user_id] ||= rand(1..3)
              hw_index = assignments.index do |assignment|
                assignment.assessment&.id == participation.assessment_id
              end
              if hw_index && hw_index >= cutoff
                participation.destroy!
                next
              end
            end

            submission_rate = submission_rate_for(profile)

            if rand < 0.03
              participation.update!(status: :exempt, submitted_at: nil)
            elsif rand > submission_rate
              if future_deadline
                participation.destroy!
              else
                participation.update!(submitted_at: nil)
              end
            elsif future_deadline || (recent_deadline && rand < 0.6)
              next
            else
              base_time = participation.submitted_at || Time.current
              grader_id = tutorial.tutors.first&.id
              participation.update!(
                status: :reviewed,
                graded_at: base_time + rand(1..48).hours,
                grader_id: grader_id
              )
            end
          end
        end

        Rails.logger.debug("Randomized participation statuses for lecture 1 demo assignments.")
      end

      def seed_demo_task_points!(lecture)
        demo_assignments(lecture).each do |assignment|
          seed_task_points_for(assignment.assessment)
        end

        Rails.logger.debug("Seeded task points for reviewed demo participations.")
      end

      def seed_demo_talk_grades!
        seminar = seminar!
        graded_count = 0
        skipped_count = 0
        german_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]

        demo_seminar_talks(seminar).includes(:speakers).find_each do |talk|
          talk.ensure_gradebook!
          assessment = talk.assessment

          if talk.speakers.empty?
            skipped_count += 1
            next
          end

          assessment.assessment_participations.delete_all

          talk.speakers.each do |speaker|
            assessment.assessment_participations.create!(
              user: speaker,
              status: :reviewed,
              grade_numeric: german_grades.sample,
              graded_at: Time.current - rand(1..72).hours,
              grader: seminar.teacher
            )
            graded_count += 1
          end
        end

        Rails.logger.debug do
          "Seeded grades for #{graded_count} demo seminar talk participations " \
            "(#{skipped_count} talks without speakers)."
        end
      end

      def seed_task_points_for(assessment)
        return unless assessment&.requires_points?

        assessable = assessment.assessable
        return if assessable.respond_to?(:deadline) && assessable.deadline&.future?

        tasks = assessment.tasks.order(:position)
        return if tasks.empty?

        participation_ids = assessment.assessment_participations.select(:id)
        Assessment::TaskPoint.where(
          assessment_participation_id: participation_ids
        ).delete_all
        assessment.assessment_participations.where.not(points_total: nil)
                  .update_all(points_total: nil)

        gradeable = assessment.assessment_participations
                              .where(status: :reviewed)
                              .where.not(submitted_at: nil)
        return if gradeable.empty?

        gradeable.find_each do |participation|
          total = 0.0

          tasks.each do |task|
            raw = (student_quality(participation.user_id) * task.max_points) +
                  rand(-1.0..1.0)
            half_steps = (raw * 2).round.clamp(0, (task.max_points * 2).to_i)
            points = half_steps / 2.0
            Assessment::TaskPoint.create!(
              assessment_participation: participation,
              task: task,
              points: points,
              grader_id: participation.grader_id
            )
            total += points
          end

          participation.update!(points_total: total)
        end
      end

      def print_assessment_summary(lecture)
        Rails.logger.debug("Assessment Summary")
        Rails.logger.debug do
          "Assessment                           " \
            "Revwd   Pendng   No-sub   Absent   Exempt   Points"
        end

        demo_assignments(lecture).each do |assignment|
          assessment = assignment.assessment
          next unless assessment

          participations = assessment.assessment_participations
          reviewed = participations.where(status: :reviewed).count
          pending_sub = participations.where(status: :pending)
                                      .where.not(submitted_at: nil).count
          pending_nosub = participations.where(status: :pending, submitted_at: nil).count
          absent = participations.where(status: :absent).count
          exempt = participations.where(status: :exempt).count
          points = Assessment::TaskPoint
                   .where(assessment_participation_id: participations.select(:id))
                   .select(:assessment_participation_id).distinct.count

          Rails.logger.debug(format(
                               "%-35<name>s %8<r>s %8<p>s %8<ns>s %8<a>s %8<e>s %8<pt>s",
                               name: assignment.title.truncate(35),
                               r: reviewed,
                               p: pending_sub,
                               ns: pending_nosub,
                               a: absent,
                               e: exempt,
                               pt: points
                             ))
        end

        Rails.logger.debug("")

        seminar = Lecture.find_by(course: Course.find_by(title: SEMINAR_COURSE_TITLE))
        return unless seminar

        demo_seminar_talks(seminar).each do |talk|
          next unless talk.assessment

          grades = talk.assessment.assessment_participations
                       .where.not(grade_numeric: nil)
                       .pluck(:grade_numeric)
          next if grades.empty?

          Rails.logger.debug { "#{talk.title}: #{grades.join(", ")}" }
        end

        Rails.logger.debug("")
      end

      def demo_seminar_talks(seminar)
        seminar.talks.where(title: SEMINAR_TALK_TITLES).order(:position)
      end

      def student_profile(user_id)
        bucket = user_id.hash.abs % 100
        if bucket < 15
          :top
        elsif bucket < 60
          :good
        elsif bucket < 75
          :struggling
        elsif bucket < 90
          :dropout
        else
          :occasional
        end
      end

      def student_quality(user_id)
        rng = Random.new(user_id.hash)

        case student_profile(user_id)
        when :top
          rng.rand(0.82..0.98)
        when :good
          rng.rand(0.55..0.82)
        when :struggling
          rng.rand(0.20..0.50)
        when :dropout
          rng.rand(0.55..0.85)
        when :occasional
          rng.rand(0.40..0.70)
        end
      end

      def submission_rate_for(profile)
        case profile
        when :top
          rand(0.93..0.99)
        when :good
          rand(0.83..0.95)
        when :struggling
          rand(0.60..0.80)
        when :dropout
          rand(0.80..0.95)
        when :occasional
          rand(0.55..0.75)
        end
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
