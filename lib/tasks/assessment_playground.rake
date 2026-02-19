# Assessment Playground
#
# Rake tasks for populating the database with test assessment data.
# Use after running solver:create_campaign and finalizing the campaign in the GUI.
#
# ## Lazy Participation Creation Model
#
# In production, Assessment::Participation records are created lazily:
# - When a student submits work → status: :submitted
# - When a tutor grades → status: :graded
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
# assessment:randomize_statuses  - Randomizes: some graded, some exempt, some deleted
# assessment:setup               - Runs all of the above
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

    assignments = [
      { title: "Homework 1 - Past deadline", deadline: 2.weeks.ago },
      { title: "Homework 2 - Recent deadline", deadline: 3.days.ago },
      { title: "Homework 3 - Future deadline", deadline: 1.week.from_now }
    ]

    assignments.each do |attrs|
      existing = lecture.assignments.find_by(title: attrs[:title])
      if existing
        puts "  ✓ Assignment already exists: #{attrs[:title]}"
        next
      end

      assignment = lecture.assignments.create!(
        title: attrs[:title],
        deadline: attrs[:deadline],
        deletion_date: attrs[:deadline] + 6.months,
        accepted_file_type: ".pdf"
      )
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

      point_options = [5, 10, 15, 20]
      task_count = rand(3..5)
      task_count.times do |i|
        max_points = point_options.sample
        assessment.tasks.create!(
          description: "Problem #{i + 1}",
          max_points: max_points,
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
          status: :submitted,
          submitted_at: assignment.deadline - rand(1..72).hours
        )
        created += 1
      end

      puts "✓ Created #{created} participations for: #{assignment.title}"
    end
  end

  desc "Randomize participation statuses with per-tutorial variance"
  task randomize_statuses: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    lecture.tutorials.each do |tutorial|
      submission_rate = rand(40..95) / 100.0
      grading_rate = rand(20..60) / 100.0

      participations = Assessment::Participation.where(tutorial_id: tutorial.id)
      next if participations.empty?

      participations.each do |p|
        roll = rand

        if roll < 0.02
          p.update!(status: :exempt, submitted_at: nil)
        elsif roll < (1 - submission_rate)
          p.destroy!
        elsif rand < grading_rate
          p.update!(
            status: :graded,
            graded_at: p.submitted_at + rand(1..48).hours,
            grader_id: tutorial.tutors.first&.id
          )
        end
      end

      remaining = Assessment::Participation.where(tutorial_id: tutorial.id)
      submitted = remaining.where(status: :submitted).count
      graded = remaining.where(status: :graded).count
      exempt = remaining.where(status: :exempt).count

      puts "✓ Tutorial '#{tutorial.title}': #{remaining.count} total " \
           "(#{submitted} submitted, #{graded} graded, #{exempt} exempt)"
    end
  end

  desc "Run full assessment playground setup"
  task setup: :environment do
    Rake::Task["assessment:create_assignments"].invoke
    Rake::Task["assessment:create_tasks"].invoke
    Rake::Task["assessment:seed_participations"].invoke
    Rake::Task["assessment:randomize_statuses"].invoke

    puts "\n✅ Assessment playground setup complete!"
    puts "Visit the lecture's Grading tab to see the results."
  end

  desc "Reset assessment playground (destroy test assignments)"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    test_titles = [
      "Homework 1 - Past deadline",
      "Homework 2 - Recent deadline",
      "Homework 3 - Future deadline"
    ]

    destroyed = 0
    test_titles.each do |title|
      assignment = lecture.assignments.find_by(title: title)
      next unless assignment

      assignment.destroy!
      destroyed += 1
      puts "✓ Destroyed: #{title}"
    end

    puts "Done. Destroyed #{destroyed} test assignments."
  end
end
