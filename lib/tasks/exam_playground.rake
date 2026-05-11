# Exam Playground
#
# Rake tasks for populating the database with test exams in various
# registration states. Creates three exams:
#   - Midterm Exam - Playground        (registration finalized, roster ready)
#   - Practice Exam - Open Registration (registration open, some signups)
#   - Final Exam - Draft               (campaign in draft, not yet open)
#
# Use after running solver:create_campaign (and finalizing it) so that
# tutorial memberships exist for student registrations.
#
# ## Usage
#
#   bundle exec rake exam:setup_core        # Create exams + tasks
#   bundle exec rake exam:setup_registration # Open campaigns + finalize sample roster
#   bundle exec rake exam:seed_grading_data  # Seed exam participations, points, grades
#   bundle exec rake exam:setup              # Full setup
#   bundle exec rake exam:reset              # Start over

namespace :exam do
  desc "Create a test exam for the first lecture with tutorials"
  task create_exam: :environment do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)

    lecture = find_lecture!

    puts "Using lecture: #{lecture.title} (ID: #{lecture.id})"

    create_exam_record(lecture, "Midterm Exam - Playground",
                       date: 2.weeks.ago,
                       location: "Lecture Hall A, Building 42",
                       capacity: 80,
                       description: "Playground midterm covering topics 1-5.")

    create_exam_record(lecture, "Practice Exam - Open Registration",
                       date: 4.weeks.from_now,
                       location: "Seminar Room B",
                       capacity: 60,
                       description: "Practice exam with open registration.")

    create_exam_record(lecture, "Final Exam - Draft",
                       date: 8.weeks.from_now,
                       location: "Main Auditorium",
                       capacity: 120,
                       description: "Final exam, registration not yet open.")
  end

  desc "Create tasks for the exam assessment"
  task create_tasks: :environment do
    Flipper.enable(:assessment_grading)

    lecture = find_lecture!

    playground_titles.each do |title|
      exam = Exam.find_by(lecture: lecture, title: title)
      next unless exam

      create_tasks_for(exam)
    end
  end

  desc "Seed participation records for finalized playground exams"
  task seed_participations: :environment do
    Flipper.enable(:assessment_grading)

    lecture = find_lecture!
    membership_lookup = TutorialMembership
                        .where(tutorial_id: lecture.tutorial_ids)
                        .pluck(:user_id, :tutorial_id)
                        .to_h

    lecture.exams.each do |exam|
      assessment = exam.assessment
      next unless assessment

      existing_count = assessment.assessment_participations.count
      if existing_count.positive?
        puts "✓ Participations already exist for: #{exam.title} (#{existing_count})"
        next
      end

      roster_user_ids = exam.exam_roster_entries.pluck(:user_id)
      if roster_user_ids.empty?
        puts "  ⏭ No roster entries for: #{exam.title} (run exam:setup_registration first)"
        next
      end

      created = 0
      roster_user_ids.each do |uid|
        tutorial_id = membership_lookup[uid]
        next unless tutorial_id

        assessment.assessment_participations.create!(
          user_id: uid,
          tutorial_id: tutorial_id,
          status: :pending,
          submitted_at: (exam.date || Time.current) - rand(1..4).hours
        )
        created += 1
      end

      puts "✓ Created #{created} participations for: #{exam.title}"
    end
  end

  desc "Seed random task points for reviewed exam participations"
  task seed_task_points: :environment do
    Flipper.enable(:assessment_grading)

    lecture = find_lecture!

    lecture.exams.each do |exam|
      seed_exam_task_points_for(exam.assessment, exam.title)
    end
  end

  desc "Assign random German grades to reviewed exam participations"
  task seed_grades: :environment do
    Flipper.enable(:assessment_grading)

    lecture = find_lecture!
    german_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]

    lecture.exams.each do |exam|
      seed_exam_grades_for(exam.assessment, german_grades, exam.title)
    end
  end

  desc "Run the core exam playground setup"
  task setup_core: :environment do
    old_level = ActiveRecord::Base.logger&.level
    ActiveRecord::Base.logger&.level = :warn

    Rake::Task["exam:create_exam"].invoke
    Rake::Task["exam:create_tasks"].invoke

    ActiveRecord::Base.logger&.level = old_level
  end

  desc "Seed exam grading data after registration has been finalized"
  task seed_grading_data: :environment do
    Rake::Task["exam:seed_participations"].invoke
    Rake::Task["exam:seed_task_points"].invoke
    Rake::Task["exam:seed_grades"].invoke
  end

  desc "Run full exam playground setup"
  task setup: :environment do
    old_level = ActiveRecord::Base.logger&.level
    ActiveRecord::Base.logger&.level = :warn

    Rake::Task["exam:setup_core"].invoke
    Rake::Task["exam:setup_registration"].invoke

    ActiveRecord::Base.logger&.level = old_level

    lecture = find_lecture!

    puts "\n#{"=" * 60}"
    puts "Exam Playground Summary"
    puts "=" * 60

    playground_titles.each do |title|
      exam = Exam.find_by(lecture: lecture, title: title)
      next unless exam

      campaign = exam.registration_campaign
      status = campaign&.status || "none"
      regs = campaign&.user_registrations&.count || 0
      roster = exam.exam_roster_entries.count

      puts format("  %-40<t>s  %<s>-10s  regs=%<r>d  roster=%<ro>d",
                  t: title, s: status, r: regs, ro: roster)
    end

    puts "=" * 60
    puts "✅ Exam setup complete!"
  end

  desc "Reset exam playground (destroy all playground exams + campaigns)"
  task reset: :environment do
    lecture = find_lecture!

    playground_titles.each do |title|
      exam = Exam.find_by(lecture: lecture, title: title)
      destroy_exam_and_campaign(exam, lecture) if exam
    end

    puts "Done."
  end

  def find_lecture!
    lecture = Lecture.joins(:tutorials).distinct.first
    abort("No lecture with tutorials found.") unless lecture
    lecture
  end

  def playground_titles
    [
      "Midterm Exam - Playground",
      "Practice Exam - Open Registration",
      "Final Exam - Draft"
    ]
  end

  def create_exam_record(lecture, title, **attrs)
    exam = Exam.find_by(lecture: lecture, title: title)

    if exam
      puts "  ✓ Exam already exists: #{title} (ID: #{exam.id})"
    else
      exam = Exam.create!(lecture: lecture, title: title, **attrs)
      puts "  ✓ Created exam: #{title} (ID: #{exam.id})"
    end

    assessment = exam.assessment
    if assessment
      puts "    Assessment auto-created " \
           "(requires_points: #{assessment.requires_points})"
    else
      puts "    ⚠ No assessment found — check Flipper :assessment_grading"
    end
  end

  def create_tasks_for(exam)
    assessment = exam.assessment
    unless assessment
      puts "  ⚠ No assessment for #{exam.title}"
      return
    end

    if assessment.tasks.any?
      puts "✓ Tasks already exist for #{exam.title} " \
           "(#{assessment.tasks.count} tasks)"
      return
    end

    tasks_spec = [
      { description: "Problem 1", max_points: 10, position: 1 },
      { description: "Problem 2", max_points: 15, position: 2 },
      { description: "Problem 3", max_points: 20, position: 3 },
      { description: "Problem 4", max_points: 10, position: 4 },
      { description: "Problem 5", max_points: 5, position: 5 }
    ]

    tasks_spec.each { |a| assessment.tasks.create!(a) }

    total = assessment.tasks.sum(:max_points)
    puts "✓ Created #{tasks_spec.size} tasks for #{exam.title} (#{total} pts)"
  end

  def seed_exam_grades_for(assessment, german_grades, label)
    return unless assessment

    graded = assessment.assessment_participations.where(status: :reviewed)
    if graded.empty?
      puts "  ⏭ No reviewed participations for: #{label}"
      return
    end

    already_graded = graded.where.not(grade_numeric: nil).count
    if already_graded == graded.count
      puts "  ✓ Grades already set for: #{label} (#{already_graded})"
      return
    end

    graded.where(grade_numeric: nil).find_each do |participation|
      participation.update!(grade_numeric: german_grades.sample)
    end

    puts "  ✓ Assigned grades to #{graded.count} participations for: #{label}"
  end

  def seed_exam_task_points_for(assessment, label)
    return unless assessment&.requires_points?

    if assessment.assessment_participations.empty?
      puts "  ⏭ No participations for: #{label}"
      return
    end

    tasks = assessment.tasks.order(:position)
    if tasks.empty?
      puts "  ⏭ No tasks for: #{label}"
      return
    end

    all_participation_ids = assessment.assessment_participations.select(:id)
    Assessment::TaskPoint
      .where(assessment_participation_id: all_participation_ids)
      .delete_all
    # rubocop:disable Rails/SkipsModelValidations
    assessment.assessment_participations
              .where.not(points_total: nil)
              .update_all(points_total: nil)
    # rubocop:enable Rails/SkipsModelValidations

    reviewable = assessment.assessment_participations.where(status: :reviewed)
    if reviewable.empty?
      reviewable = assessment.assessment_participations.where(status: :pending)
      reviewable.find_each do |participation|
        participation.update!(status: :reviewed)
      end
    end

    if reviewable.empty?
      puts "  ⏭ No reviewed participations for: #{label}"
      return
    end

    reviewable.find_each do |participation|
      quality = exam_student_quality(participation.user_id)
      total = 0.0
      tasks.each do |task|
        raw = (quality * task.max_points) + rand(-1.0..1.0)
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

    puts "  ✓ Seeded task points for #{reviewable.count} participations: #{label}"
  end

  def register_users(exam, user_ids, ratio: 0.9)
    return unless exam

    campaign = exam.registration_campaign
    return unless campaign

    exam_item = campaign.registration_items
                        .find_by(registerable_type: "Exam")
    return unless exam_item

    existing = campaign.user_registrations.count
    if existing.positive?
      puts "✓ #{exam.title}: #{existing} registrations exist. Skipping."
      return
    end

    registered = 0
    user_ids.each do |uid|
      next if rand > ratio

      FactoryBot.create(:registration_user_registration,
                        user_id: uid,
                        registration_campaign: campaign,
                        registration_item: exam_item,
                        status: :confirmed)
      registered += 1
    end

    puts "✓ #{exam.title}: #{registered} registrations " \
         "(#{(ratio * 100).to_i}% rate)"
  end

  def destroy_exam_and_campaign(exam, _lecture)
    campaign = exam.registration_campaign

    if campaign
      campaign.update_column(:status, 0) # rubocop:disable Rails/SkipsModelValidations
      campaign.reload
      campaign.user_registrations.delete_all
      campaign.registration_items.delete_all
      exam.exam_roster_entries.delete_all
      campaign.delete
    end

    if exam.assessment
      pid = exam.assessment.assessment_participations.select(:id)
      Assessment::TaskPoint.where(assessment_participation_id: pid).delete_all
      exam.assessment.assessment_participations.delete_all
      exam.assessment.tasks.delete_all
      Assessment::GradeScheme.where(
        assessment_id: exam.assessment.id
      ).delete_all
      exam.assessment.delete
    end

    exam.delete
    puts "✓ Destroyed: #{exam.title}"
  end

  def exam_student_profile(user_id)
    bucket = user_id.hash.abs % 100
    if bucket < 15 then :top
    elsif bucket < 60 then :good
    elsif bucket < 75 then :struggling
    elsif bucket < 90 then :dropout
    else
      :occasional
    end
  end

  def exam_student_quality(user_id)
    rng = Random.new(user_id.hash)
    case exam_student_profile(user_id)
    when :top then rng.rand(0.82..0.98)
    when :good then rng.rand(0.55..0.82)
    when :struggling then rng.rand(0.20..0.50)
    when :dropout then rng.rand(0.55..0.85)
    when :occasional then rng.rand(0.40..0.70)
    end
  end
end
