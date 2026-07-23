module Demo
  module PerformanceSetupSupport
    DEMO_ACHIEVEMENT_ATTRIBUTES = [
      { title: "Blackboard Talk", value_type: :boolean, threshold: nil },
      { title: "Homework Points", value_type: :numeric, threshold: 15 },
      { title: "Attendance Rate", value_type: :percentage, threshold: 80.0 }
    ].freeze

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

          Rails.logger.debug do
            "#{achievement.title}: #{graded} graded, #{ungraded} ungraded"
          end
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
