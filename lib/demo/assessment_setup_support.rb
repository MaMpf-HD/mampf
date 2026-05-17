module Demo
  module AssessmentSetupSupport
    def setup_assessment!
      setup_flags!

      lecture = nil
      Demo::QuietLoggingSupport.with_quiet_logging do
        lecture = assessment_lecture!
      end

      Rails.logger.debug("=== Demo Assessment Setup ===")
      Demo::QuietLoggingSupport.with_quiet_logging do
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

      raise("Lecture 1 has no tutorial roster. Run demo:rosters first.")
    end

    private

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
          # rubocop:disable Rails/SkipsModelValidations
          assignment.update_column(:deadline, attrs[:deadline])
          # rubocop:enable Rails/SkipsModelValidations
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
        assessment.assessment_participations.where.not(
          points_total: nil
        ).find_each do |participation|
          participation.update!(points_total: nil)
        end

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

        seminar = Lecture.find_by(
          course: Course.find_by(title: Demo::SetupSupport::SEMINAR_COURSE_TITLE)
        )
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
        seminar.talks.where(
          title: Demo::SetupSupport::SEMINAR_TALK_TITLES
        ).order(:position)
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
  end
end
