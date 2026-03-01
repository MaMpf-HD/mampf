namespace :performance do
  desc "Set up rule, achievements, and compute performance records"
  task compute: :environment do
    Flipper.enable(:student_performance)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    puts "Lecture: #{lecture.title}"

    setup_rule_and_achievements(lecture)

    puts "\nComputing performance records..."
    service = StudentPerformance::ComputationService.new(lecture: lecture)
    service.compute_and_upsert_all_records!

    count = lecture.student_performance_records.count
    puts "✓ Computed #{count} performance records."
  end

  desc "Reset performance records, rule, and achievements for the first lecture"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    return unless lecture

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

def setup_rule_and_achievements(lecture)
  rule = StudentPerformance::Rule.find_or_initialize_by(lecture: lecture)
  rule.update!(min_percentage: 50, active: true)
  puts "✓ Rule: min 50% of total points"

  presentation = Achievement.find_or_create_by!(
    lecture: lecture,
    title: "Blackboard Presentation",
    value_type: :boolean
  )
  puts "  Achievement: #{presentation.title} (#{presentation.value_type})"

  attendance = Achievement.find_or_create_by!(
    lecture: lecture,
    title: "Tutorial Attendance"
  ) do |a|
    a.value_type = :numeric
    a.threshold = 10
  end
  attendance.update!(value_type: :numeric, threshold: 10)
  puts "  Achievement: #{attendance.title} (min. #{attendance.threshold})"

  [presentation, attendance].each do |achievement|
    StudentPerformance::RuleAchievement.find_or_create_by!(
      rule: rule,
      achievement: achievement
    ) do |ra|
      ra.position = rule.rule_achievements.count + 1
    end
  end

  puts "✓ Rule has #{rule.rule_achievements.count} required achievements"
end
