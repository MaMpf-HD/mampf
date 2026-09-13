module Scenarios
  module PerformanceSetupSupport
    DEMO_ACHIEVEMENT_ATTRIBUTES = [
      { title: "Blackboard Talk", value_type: :boolean, threshold: nil },
      { title: "Homework Points", value_type: :numeric, threshold: 15 },
      { title: "Attendance Rate", value_type: :percentage, threshold: 80.0 }
    ].freeze

    def setup_performance!
      lecture = nil
      Scenarios::QuietLoggingSupport.with_quiet_logging do
        lecture = performance_lecture!
      end

      Rails.logger.debug("=== Demo Performance Setup ===")
      Scenarios::QuietLoggingSupport.with_quiet_logging do
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
      abort("Lecture 1 has no demo assignments. Run just seed first.")
      # rubocop:enable Rails/Exit
    end

    private

      def demo_achievement_titles
        DEMO_ACHIEVEMENT_ATTRIBUTES.pluck(:title)
      end

      def demo_achievements(lecture)
        lecture.achievements.where(title: demo_achievement_titles).order(:title)
      end

      def create_demo_achievements!(lecture)
        # A student seated in more than one tutorial (the roster's random
        # allocation allows it) still gets one participation, not one per seat.
        memberships = TutorialMembership.where(tutorial_id: staffed_tutorial_ids(lecture))
                                        .pluck(:user_id, :tutorial_id).to_h

        DEMO_ACHIEVEMENT_ATTRIBUTES.each do |attrs|
          achievement = lecture.achievements.create!(attrs)
          achievement.ensure_assessment!(
            requires_points: false,
            requires_submission: false
          )

          assessment = achievement.assessment
          # Achievement#after_create already seeded a participation per
          # lecture member; only the staffed tutorials' students are meant
          # to have one, each with the tutorial this loop assigns them.
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
        user_ids = TutorialMembership.where(tutorial_id: staffed_tutorial_ids(lecture))
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
          quality > 0.5 ? Achievement::PASSED : "fail"
        when "numeric"
          max = (achievement.threshold * 1.5).ceil
          (quality * max).round.to_s
        when "percentage"
          (quality * 100).round(1).to_s
        end
      end
  end
end
