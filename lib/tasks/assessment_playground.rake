# Assessment Playground
#
# Rake tasks for populating the database with test assessment data.
# Use after running solver:create_campaign and finalizing the campaign in the GUI.
#
# ## Lazy Participation Creation Model
#
# In production, Assessment::Participation records are created lazily:
# - When a student submits work → status: :pending
# - When a tutor reviews → status: :reviewed
# - When marked absent → status: :absent
# - When marked exempt → status: :exempt
#
# The absence of a participation record means "not started".
# Expected counts come from the roster (TutorialMembership), not from
# pre-seeded participation records.
#
# ## Tasks
#
# assessment:create_assignments  - Creates 3 test assignments
# assessment:create_tasks        - Creates 3-5 random tasks per assignment
# assessment:seed_participations - Seeds participations (simulates submissions)
# assessment:randomize_statuses  - Randomizes: some reviewed, some exempt, some deleted
# assessment:seed_grades         - Assigns random German grades to reviewed participations
# assessment:seed_achievement_grades - Seeds achievements and grade_text values
# assessment:seed_seminar_grades - Grades speakers in the two-stage seminar campaign
# assessment:setup               - Runs all of the above (except seed_seminar_grades)
# assessment:reset               - Destroys test assignments
#
# ## Usage
#
#   bundle exec rake assessment:setup    # Full setup
#   bundle exec rake assessment:reset    # Start over
#
# ## Per-Tutorial Variance
#
# randomize_statuses applies different submission rates (40-95%) per tutorial
# to create realistic-looking data for the Grading Overview component.
# Some participations are deleted to simulate non-submitters.

namespace :assessment do
  desc "Create test assignments for the first lecture with tutorials"
  task create_assignments: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found. Run solver:create_campaign first." unless lecture

    puts "Creating assignments for lecture: #{lecture.title}"

    assignments = (1..10).map do |i|
      deadline = i < 10 ? (10 - i).weeks.ago : 3.days.ago
      { title: "Homework #{i}", deadline: deadline }
    end

    assignments.each do |attrs|
      existing = lecture.assignments.find_by(title: attrs[:title])
      if existing
        puts "  ✓ Assignment already exists: #{attrs[:title]}"
        next
      end

      assignment = lecture.assignments.create!(
        title: attrs[:title],
        deadline: 1.year.from_now,
        accepted_file_type: ".pdf"
      )
      assignment.update_column(:deadline, attrs[:deadline])
      puts "  ✓ Created: #{assignment.title} (deadline: #{assignment.deadline})"
    end

    puts "Done. Created #{lecture.assignments.count} assignments."
  end

  desc "Create random tasks for each assignment"
  task create_tasks: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    lecture.assignments.each do |assignment|
      assessment = assignment.assessment
      next unless assessment&.requires_points?

      if assessment.tasks.any?
        puts "✓ Tasks already exist for: #{assignment.title}"
        next
      end

      task_count = rand(4..5)
      task_count.times do |i|
        assessment.tasks.create!(
          description: "Problem #{i + 1}",
          max_points: 4,
          position: i + 1
        )
      end

      total = assessment.tasks.sum(:max_points)
      puts "✓ Created #{task_count} tasks for #{assignment.title} (total: #{total} pts)"
    end
  end

  desc "Seed participation records from tutorial memberships (lazy creation simulation)"
  task seed_participations: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    lecture.assignments.each do |assignment|
      assessment = assignment.assessment
      next unless assessment

      existing_count = assessment.assessment_participations.count
      if existing_count.positive?
        puts "✓ Participations already exist for: #{assignment.title} (#{existing_count})"
        next
      end

      memberships = TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
      created = 0

      memberships.find_each do |membership|
        assessment.assessment_participations.create!(
          user_id: membership.user_id,
          tutorial_id: membership.tutorial_id,
          status: :pending,
          submitted_at: assignment.deadline - rand(1..72).hours
        )
        created += 1
      end

      puts "✓ Created #{created} participations for: #{assignment.title}"
    end

    if lecture.respond_to?(:exams)
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

        roster_user_ids = exam.exam_rosters.pluck(:user_id)
        if roster_user_ids.empty?
          puts "  ⏭ No roster entries for: #{exam.title} (run exam:setup first)"
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
  end

  desc "Randomize participation statuses with per-tutorial variance"
  task randomize_statuses: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    sorted_assignments = lecture.assignments.order(:deadline)
    dropout_cutoffs = {}

    lecture.tutorials.each do |tutorial|
      grader_id = tutorial.tutors.first&.id

      participations = Assessment::Participation
                       .where(tutorial_id: tutorial.id)
                       .includes(assessment: :assessable)
      next if participations.empty?

      participations.each do |p|
        is_physical = p.assessment.assessable_type.in?(["Exam", "Talk"])
        assessable = p.assessment.assessable
        future_deadline = assessable.respond_to?(:deadline) &&
                          assessable.deadline&.future?
        recent_deadline = !future_deadline &&
                          assessable.respond_to?(:deadline) &&
                          assessable.deadline &&
                          assessable.deadline > 1.week.ago

        profile = student_profile(p.user_id)

        if profile == :dropout && !is_physical
          cutoff = dropout_cutoffs[p.user_id] ||= rand(1..3)
          hw_index = sorted_assignments.index do |a|
            a.assessment&.id == p.assessment_id
          end
          if hw_index && hw_index >= cutoff
            p.destroy!
            next
          end
        end

        sub_rate = submission_rate_for(profile)

        if rand < 0.03
          p.update!(status: :exempt, submitted_at: nil)
        elsif is_physical && rand < 0.10
          p.update!(status: :absent, submitted_at: nil)
        elsif !is_physical && rand > sub_rate
          if future_deadline
            p.destroy!
          else
            p.update!(submitted_at: nil)
          end
        elsif future_deadline || (recent_deadline && rand < 0.6)
          next
        else
          base_time = p.submitted_at || Time.current
          p.update!(
            status: :reviewed,
            graded_at: base_time + rand(1..48).hours,
            grader_id: grader_id
          )
        end
      end

      remaining = Assessment::Participation.where(tutorial_id: tutorial.id)
      pending = remaining.where(status: :pending).count
      reviewed = remaining.where(status: :reviewed).count
      absent = remaining.where(status: :absent).count
      exempt = remaining.where(status: :exempt).count

      puts "✓ Tutorial '#{tutorial.title}': #{remaining.count} total " \
           "(#{pending} pending, #{reviewed} reviewed, " \
           "#{absent} absent, #{exempt} exempt)"
    end
  end

  desc "Assign random German grades to reviewed participations"
  task seed_grades: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    german_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]

    if lecture.respond_to?(:talks)
      lecture.talks.each do |talk|
        seed_grades_for(talk.assessment, german_grades, talk.title)
      end
    end

    if lecture.respond_to?(:exams)
      lecture.exams.each do |exam|
        seed_grades_for(exam.assessment, german_grades, exam.title)
      end
    end
  end

  desc "Seed random task points for reviewed participations"
  task seed_task_points: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    lecture.assignments.each do |assignment|
      seed_task_points_for(assignment.assessment, assignment.title)
    end

    if lecture.respond_to?(:exams)
      lecture.exams.each do |exam|
        seed_task_points_for(exam.assessment, exam.title)
      end
    end
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

    achievement_defs.each do |defn|
      achievement = lecture.achievements.find_or_create_by!(title: defn[:title]) do |a|
        a.value_type = defn[:value_type]
        a.threshold = defn[:threshold]
      end
      assessment = achievement.ensure_assessment!(
        requires_points: false, requires_submission: false
      )

      existing = assessment.assessment_participations.count
      if existing.positive?
        puts "  ✓ Participations exist for: #{defn[:title]} (#{existing})"
      else
        memberships.each do |uid, tid|
          assessment.assessment_participations.create!(
            user_id: uid, tutorial_id: tid, status: :reviewed
          )
        end
        puts "  ✓ Created #{memberships.size} participations " \
             "for: #{defn[:title]}"
      end

      seed_achievement_grade_text(assessment, achievement, defn[:title])
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

  desc "Run full assessment playground setup"
  task setup: :environment do
    old_level = ActiveRecord::Base.logger&.level
    ActiveRecord::Base.logger&.level = :warn

    clean_invalid_grades!

    Rake::Task["assessment:create_assignments"].invoke
    Rake::Task["assessment:create_tasks"].invoke
    Rake::Task["assessment:seed_participations"].invoke
    Rake::Task["assessment:randomize_statuses"].invoke
    Rake::Task["assessment:seed_task_points"].invoke
    Rake::Task["assessment:seed_grades"].invoke
    Rake::Task["assessment:seed_achievement_grades"].invoke

    print_summary

    ActiveRecord::Base.logger&.level = old_level
  end

  desc "Reset assessment playground (destroy test assignments)"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    test_titles = (1..10).map { |i| "Homework #{i}" }
    test_titles += [
      "Homework 1 - Past deadline",
      "Homework 2 - Recent deadline",
      "Homework 3 - Future deadline"
    ]

    destroyed = 0
    test_titles.each do |title|
      assignment = lecture.assignments.find_by(title: title)
      next unless assignment

      if assignment.assessment
        pid = assignment.assessment.assessment_participations.select(:id)
        Assessment::TaskPoint.where(assessment_participation_id: pid).delete_all
        assignment.assessment.assessment_participations.delete_all
        assignment.assessment.tasks.delete_all
      end

      assignment.destroy!
      destroyed += 1
      puts "✓ Destroyed: #{title}"
    end

    puts "Done. Destroyed #{destroyed} test assignments."

    achievement_titles = ["Blackboard Talk", "Homework Points",
                          "Attendance Rate"]
    achievement_titles.each do |title|
      achievement = lecture.achievements.find_by(title: title)
      next unless achievement

      if achievement.assessment
        achievement.assessment.assessment_participations.delete_all
        achievement.assessment.destroy!
      end
      achievement.destroy!
      puts "✓ Destroyed achievement: #{title}"
    end
  end

  def print_summary
    lecture = Lecture.joins(:tutorials).distinct.first
    return unless lecture

    puts "\n#{"=" * 85}"
    puts "Assessment Playground Summary"
    puts "=" * 85
    puts "Assessment                           Revwd   Pendng   No-sub   Absent   " \
         "Exempt   Grades   Points"
    puts "-" * 85

    assessables = lecture.assignments.map { |a| [a.title, a.assessment, a] }
    if lecture.respond_to?(:talks)
      assessables += lecture.talks.map { |t| [t.title, t.assessment, t] }
    end
    if lecture.respond_to?(:exams)
      assessables += lecture.exams.map { |e| [e.title, e.assessment, e] }
    end

    assessables.each do |label, assessment, assessable|
      next unless assessment

      parts = assessment.assessment_participations
      reviewed = parts.where(status: :reviewed).count
      pending_sub = parts.where(status: :pending)
                         .where.not(submitted_at: nil).count
      pending_nosub = parts.where(status: :pending, submitted_at: nil).count
      absent = parts.where(status: :absent).count
      exempt = parts.where(status: :exempt).count
      gradable = assessable.is_a?(Assessment::Gradable)
      grades = gradable ? parts.where.not(grade_numeric: nil).count : "-"
      pointable = assessable.is_a?(Assessment::Pointable)
      points = if pointable
        Assessment::TaskPoint
          .where(assessment_participation_id: parts.select(:id))
          .select(:assessment_participation_id).distinct.count
      else
        "-"
      end
      puts format(
        "%-35<name>s %8<r>s %8<p>s %8<ns>s %8<a>s %8<e>s %8<g>s %8<pt>s",
        name: label.truncate(35), r: reviewed, p: pending_sub,
        ns: pending_nosub, a: absent, e: exempt, g: grades, pt: points
      )
    end

    puts "=" * 85
    puts "✅ Setup complete! Visit the lecture's Grading tab."
  end

  desc "Seed grades for talks in the two-stage seminar campaign"
  task seed_seminar_grades: :environment do
    Flipper.enable(:assessment_grading)

    course = Course.find_by(title: "Campaign Test Seminar")
    abort "Seminar course not found. Run solver:create_two_stage_campaign first." unless course

    seminar = Lecture.find_by(course: course)
    abort "Seminar lecture not found." unless seminar

    german_grades = [1.0, 1.3, 1.7, 2.0, 2.3, 2.7, 3.0, 3.3, 3.7, 4.0, 5.0]
    graded_count = 0
    skipped_count = 0

    seminar.talks.includes(:speakers).find_each do |talk|
      assessment = talk.assessment
      unless assessment
        puts "  ⏭ No assessment for talk: #{talk.title}"
        skipped_count += 1
        next
      end

      if talk.speakers.empty?
        puts "  ⏭ No speakers for talk: #{talk.title}"
        skipped_count += 1
        next
      end

      talk.speakers.each do |speaker|
        participation = assessment.assessment_participations
                                  .find_or_initialize_by(user: speaker)

        if participation.grade_numeric.present?
          puts "  ✓ Already graded: #{speaker.tutorial_name} → #{talk.title}"
          next
        end

        grade = german_grades.sample
        participation.assign_attributes(
          status: :reviewed,
          grade_numeric: grade,
          graded_at: Time.current - rand(1..72).hours,
          grader: seminar.teacher
        )
        participation.save!
        graded_count += 1
      end
    end

    puts "\nDone. Graded #{graded_count} talk participations, " \
         "skipped #{skipped_count} talks."
  end

  def seed_grades_for(assessment, german_grades, label)
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

    graded.where(grade_numeric: nil).find_each do |p|
      grade = german_grades.sample
      p.update!(grade_numeric: grade)
    end

    puts "  ✓ Assigned grades to #{graded.count} participations for: #{label}"
  end

  def seed_task_points_for(assessment, label)
    return unless assessment&.requires_points?

    assessable = assessment.assessable
    if assessable.respond_to?(:deadline) && assessable.deadline&.future?
      puts "  ⏭ Deadline not yet passed for: #{label}"
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

    gradeable = assessment.assessment_participations
                          .where(status: :reviewed)
                          .where.not(submitted_at: nil)
    if gradeable.empty?
      puts "  ⏭ No reviewed participations for: #{label}"
      return
    end

    gradeable.find_each do |participation|
      quality = student_quality(participation.user_id)
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

    puts "  ✓ Seeded task points for #{gradeable.count} participations: #{label}"
  end

  def clean_invalid_grades!
    non_gradable_ids = Assessment::Assessment
                       .includes(:assessable)
                       .reject { |a| a.assessable.is_a?(Assessment::Gradable) }
                       .map(&:id)
    return if non_gradable_ids.empty?

    dirty = Assessment::Participation
            .where(assessment_id: non_gradable_ids)
            .where.not(grade_numeric: nil)
    return if dirty.empty?

    # rubocop:disable Rails/SkipsModelValidations
    dirty.update_all(grade_numeric: nil, grade_text: nil)
    # rubocop:enable Rails/SkipsModelValidations
    puts "⚠ Cleaned #{dirty.count} invalid grade_numeric values " \
         "on non-gradable assessments"
  end

  def student_profile(user_id)
    bucket = user_id.hash.abs % 100
    if bucket < 15 then :top
    elsif bucket < 60 then :good
    elsif bucket < 75 then :struggling
    elsif bucket < 90 then :dropout
    else
      :occasional
    end
  end

  def student_quality(user_id)
    rng = Random.new(user_id.hash)
    case student_profile(user_id)
    when :top then rng.rand(0.82..0.98)
    when :good then rng.rand(0.55..0.82)
    when :struggling then rng.rand(0.20..0.50)
    when :dropout then rng.rand(0.55..0.85)
    when :occasional then rng.rand(0.40..0.70)
    end
  end

  def submission_rate_for(profile)
    case profile
    when :top then rand(0.93..0.99)
    when :good then rand(0.83..0.95)
    when :struggling then rand(0.60..0.80)
    when :dropout then rand(0.80..0.95)
    when :occasional then rand(0.55..0.75)
    end
  end

  def seed_achievement_grade_text(assessment, achievement, label)
    ungradeable = assessment.assessment_participations
                            .where(grade_text: [nil, ""])
    count = ungradeable.count
    if count.zero?
      puts "  ✓ Grades already set for: #{label}"
      return
    end

    graded = 0
    ungradeable.find_each do |p|
      if rand < 0.1
        graded += 1
        next
      end
      quality = student_quality(p.user_id)
      p.update!(grade_text: random_grade_text(achievement, quality))
    end

    puts "  ✓ Seeded grade_text for #{count - graded} " \
         "participations (#{graded} left ungraded): #{label}"
  end

  def random_grade_text(achievement, quality)
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
end
