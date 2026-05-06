namespace :performance do
  desc "Seed achievements and compute performance records"
  task setup: :environment do
    Rake::Task["performance:seed_achievement_grades"].invoke
    Rake::Task["performance:compute"].invoke
  end

  desc "Set up rule and compute performance records"
  task compute: :environment do
    Flipper.enable(:student_performance)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    puts "Lecture: #{lecture.title}"

    setup_rule(lecture)

    puts "\nComputing performance records..."
    service = StudentPerformance::ComputationService.new(lecture: lecture)
    service.compute_and_upsert_all_records!

    count = lecture.student_performance_records.count
    puts "✓ Computed #{count} performance records."
  end

  desc "Seed achievements and grade_text values for achievement participations"
  task seed_achievement_grades: :environment do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:student_performance)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    achievement_defs = [
      { title: "Blackboard Talk", value_type: :boolean, threshold: nil },
      { title: "Homework Points", value_type: :numeric, threshold: 15 },
      { title: "Attendance Rate", value_type: :percentage, threshold: 80.0 }
    ]

    memberships = TutorialMembership
                  .where(tutorial_id: lecture.tutorial_ids)
                  .pluck(:user_id, :tutorial_id)
                  .to_h

    abort "No tutorial memberships found for lecture." if memberships.empty?

    achievement_defs.each do |definition|
      achievement = lecture.achievements.find_or_create_by!(title: definition[:title]) do |record|
        record.value_type = definition[:value_type]
        record.threshold = definition[:threshold]
      end
      assessment = achievement.ensure_assessment!(
        requires_points: false, requires_submission: false
      )

      existing = assessment.assessment_participations.count
      if existing.positive?
        puts "  ✓ Participations exist for: #{definition[:title]} (#{existing})"
      else
        memberships.each do |user_id, tutorial_id|
          assessment.assessment_participations.create!(
            user_id: user_id,
            tutorial_id: tutorial_id,
            status: :reviewed
          )
        end
        puts "  ✓ Created #{memberships.size} participations for: #{definition[:title]}"
      end

      seed_performance_achievement_grade_text(
        assessment,
        achievement,
        definition[:title]
      )
    end

    puts "✅ Achievement grades seeded."
  end

  desc "Clear all achievement grade_text values"
  task reset_achievement_grades: :environment do
    ids = Assessment::Assessment.where(assessable_type: "Achievement")
                                .pluck(:id)
    count = Assessment::Participation
            .where(assessment_id: ids)
            .where.not(grade_text: [nil, ""])
            .update_all(grade_text: nil) # rubocop:disable Rails/SkipsModelValidations
    puts "✅ Cleared grade_text for #{count} achievement participations."
  end

  desc "Reset performance records, rule, and achievements for the first lecture"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    return unless lecture

    deleted_certs = StudentPerformance::Certification.where(lecture: lecture).delete_all
    puts "✓ Deleted #{deleted_certs} certifications."

    records = lecture.student_performance_records.delete_all
    puts "✓ Deleted #{records} performance records."

    rule = StudentPerformance::Rule.find_by(lecture: lecture)
    if rule
      rule.rule_achievements.delete_all
      rule.destroy!
      puts "✓ Deleted rule."
    end

    achievements = Achievement.where(lecture: lecture).destroy_all
    puts "✓ Deleted #{achievements.size} achievements."
  end
end

def setup_rule(lecture)
  rule = StudentPerformance::Rule.find_or_initialize_by(lecture: lecture)
  rule.update!(min_percentage: 50, active: true)
  puts "✓ Rule: min 50% of total points (no achievement requirements)"

  rule.rule_achievements.delete_all
end

def seed_performance_achievement_grade_text(assessment, achievement, label)
  ungraded = assessment.assessment_participations
                       .where(grade_text: [nil, ""])
  count = ungraded.count
  if count.zero?
    puts "  ✓ Grades already set for: #{label}"
    return
  end

  skipped = 0
  ungraded.find_each do |participation|
    if rand < 0.1
      skipped += 1
      next
    end

    quality = performance_student_quality(participation.user_id)
    participation.update!(
      grade_text: performance_random_grade_text(achievement, quality)
    )
  end

  puts "  ✓ Seeded grade_text for #{count - skipped} participations " \
       "(#{skipped} left ungraded): #{label}"
end

def performance_student_quality(user_id)
  rng = Random.new(user_id.hash)
  bucket = user_id.hash.abs % 100

  case bucket
  when 0...15 then rng.rand(0.82..0.98)
  when 15...60 then rng.rand(0.55..0.82)
  when 60...75 then rng.rand(0.20..0.50)
  when 75...90 then rng.rand(0.55..0.85)
  else
    rng.rand(0.40..0.70)
  end
end

def performance_random_grade_text(achievement, quality)
  case achievement.value_type
  when "boolean"
    quality > 0.5 ? "pass" : "fail"
  when "numeric"
    max = (achievement.threshold * 1.5).ceil
    (quality * max).round.to_s
  when "percentage"
    (quality * 100).round(1).to_s
  end
end
