namespace :performance do
  desc "Compute performance records for the first lecture with tutorials"
  task compute: :environment do
    Flipper.enable(:student_performance)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    puts "Computing performance records for: #{lecture.title}"

    service = StudentPerformance::ComputationService.new(lecture: lecture)
    service.compute_and_upsert_all_records!

    count = lecture.student_performance_records.count
    puts "✓ Computed #{count} performance records."

    above_50 = lecture.student_performance_records
                      .where("percentage_materialized >= 50").count
    below_50 = lecture.student_performance_records
                      .where("percentage_materialized < 50").count
    puts "  #{above_50} above 50% | #{below_50} below 50%"
  end

  desc "Reset performance records for the first lecture"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    return unless lecture

    count = lecture.student_performance_records.delete_all
    puts "✓ Deleted #{count} performance records."
  end
end
