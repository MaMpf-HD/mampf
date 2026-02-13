# Exam Playground
#
# Rake tasks for populating the database with a test exam, its tasks,
# a registration campaign and roster entries.
# Use after running solver:create_campaign (and finalizing it) so that
# tutorial memberships exist for student registrations.
#
# ## Tasks
#
# exam:create_exam          - Creates a "Midterm Exam - Playground" on the
#                             first lecture that has tutorials
# exam:create_tasks         - Adds 5 grading tasks (60 pts total)
# exam:create_campaign      - Creates an FCFS registration campaign for the exam
# exam:create_registrations - Registers ~90% of tutorial members as confirmed
# exam:finalize_campaign    - Closes + finalizes the campaign (materializes roster)
# exam:setup                - Runs all of the above
# exam:reset                - Destroys the exam, campaign and all related data
# exam:reset_registrations  - Clears registrations + roster, re-opens the campaign
#
# ## Usage
#
#   bundle exec rake exam:setup    # Full setup
#   bundle exec rake exam:reset    # Start over

namespace :exam do
  desc "Create a test exam for the first lecture with tutorials"
  task create_exam: :environment do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found. Run solver:create_campaign first." unless lecture

    puts "Using lecture: #{lecture.title} (ID: #{lecture.id})"

    title = "Midterm Exam - Playground"
    exam = Exam.find_by(lecture: lecture, title: title)

    if exam
      puts "  ✓ Exam already exists: #{title} (ID: #{exam.id})"
    else
      exam = Exam.create!(
        lecture: lecture,
        title: title,
        date: 2.weeks.from_now,
        location: "Lecture Hall A, Building 42",
        capacity: 80,
        description: "Playground midterm covering topics 1-5."
      )
      puts "  ✓ Created exam: #{exam.title} (ID: #{exam.id})"
    end

    assessment = exam.assessment
    if assessment
      puts "  ✓ Assessment auto-created (requires_points: #{assessment.requires_points})"
    else
      puts "  ⚠ No assessment found — check Flipper :assessment_grading"
    end
  end

  desc "Create tasks for the exam assessment"
  task create_tasks: :environment do
    Flipper.enable(:assessment_grading)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    abort "Exam not found. Run exam:create_exam first." unless exam

    assessment = exam.assessment
    abort "No assessment for exam. Check Flipper :assessment_grading." unless assessment

    if assessment.tasks.any?
      puts "✓ Tasks already exist for exam (#{assessment.tasks.count} tasks, " \
           "#{assessment.tasks.sum(:max_points)} pts total)"
      next
    end

    tasks_spec = [
      { description: "Problem 1", max_points: 10, position: 1 },
      { description: "Problem 2", max_points: 15, position: 2 },
      { description: "Problem 3", max_points: 20, position: 3 },
      { description: "Problem 4", max_points: 10, position: 4 },
      { description: "Problem 5", max_points: 5, position: 5 }
    ]

    tasks_spec.each do |attrs|
      assessment.tasks.create!(attrs)
    end

    total = assessment.tasks.sum(:max_points)
    puts "✓ Created #{tasks_spec.size} tasks for #{exam.title} (total: #{total} pts)"
  end

  desc "Create a registration campaign for the exam"
  task create_campaign: :environment do
    Flipper.enable(:registration_campaigns)

    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    abort "Exam not found. Run exam:create_exam first." unless exam

    campaign_desc = "Exam Registration Campaign"
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: campaign_desc)

    if campaign
      puts "✓ Campaign already exists (ID: #{campaign.id}, status: #{campaign.status})"
    else
      campaign = FactoryBot.create(:registration_campaign,
                                   campaignable: lecture,
                                   status: :draft,
                                   allocation_mode: :first_come_first_served,
                                   registration_deadline: 1.week.from_now,
                                   description: campaign_desc)
      puts "✓ Created campaign: #{campaign.id}"
    end

    unless Registration::Item.exists?(registration_campaign: campaign, registerable: exam)
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: exam)
      puts "✓ Added exam '#{exam.title}' to campaign as registration item"
    end

    if campaign.draft?
      campaign.update!(status: :open)
      puts "✓ Opened campaign"
    end
  end

  desc "Create user registrations for the exam campaign"
  task create_registrations: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Exam Registration Campaign")
    abort "Campaign not found. Run exam:create_campaign first." unless campaign

    exam_item = campaign.registration_items
                        .find_by(registerable_type: "Exam")
    abort "No exam item in campaign." unless exam_item

    exam = exam_item.registerable
    existing = campaign.user_registrations.count

    if existing.positive?
      puts "✓ Registrations already exist (#{existing}). Skipping."
      puts "  Run exam:reset_registrations to clear and re-create."
      next
    end

    memberships = TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
    user_ids = memberships.pluck(:user_id).uniq

    if user_ids.empty?
      puts "No tutorial members found. Run solver:create_campaign + " \
           "solver:create_registrations first, then finalize that campaign."
      abort
    end

    registered = 0
    skipped = 0

    user_ids.each do |uid|
      if rand < 0.1
        skipped += 1
        next
      end

      FactoryBot.create(:registration_user_registration,
                        user_id: uid,
                        registration_campaign: campaign,
                        registration_item: exam_item,
                        status: :confirmed)
      registered += 1
    end

    puts "✓ Created #{registered} confirmed registrations " \
         "(#{skipped} students skipped ~10% no-show rate)"
    puts "  Exam capacity: #{exam.capacity || "unlimited"}, registered: #{registered}"
  end

  desc "Finalize the exam campaign (materialize roster)"
  task finalize_campaign: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Exam Registration Campaign")
    abort "Campaign not found. Run exam:create_campaign first." unless campaign

    if campaign.completed?
      puts "✓ Campaign already finalized."
      roster_count = ExamRoster.joins(:exam)
                               .where(exams: { lecture_id: lecture.id }).count
      puts "  Exam roster has #{roster_count} entries."
      next
    end

    unless campaign.closed?
      campaign.update!(status: :closed)
      puts "✓ Closed campaign"
    end

    campaign.finalize!
    puts "✓ Finalized campaign — roster materialized"

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    roster_count = exam&.exam_rosters&.count || 0
    puts "  Exam roster: #{roster_count} students"
  end

  desc "Run full exam playground setup"
  task setup: :environment do
    old_level = ActiveRecord::Base.logger&.level
    ActiveRecord::Base.logger&.level = :warn

    Rake::Task["exam:create_exam"].invoke
    Rake::Task["exam:create_tasks"].invoke
    Rake::Task["exam:create_campaign"].invoke
    Rake::Task["exam:create_registrations"].invoke
    Rake::Task["exam:finalize_campaign"].invoke

    ActiveRecord::Base.logger&.level = old_level

    lecture = Lecture.joins(:tutorials).distinct.first
    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Exam Registration Campaign")

    puts "\n#{"=" * 60}"
    puts "Exam Playground Summary"
    puts "=" * 60

    if exam
      assessment = exam.assessment
      tasks_count = assessment&.tasks&.count || 0
      total_pts = assessment&.tasks&.sum(:max_points) || 0
      roster_count = exam.exam_rosters.count
      puts format("%-25<k>s %<v>s", k: "Exam:", v: exam.title)
      date_str = exam.date&.strftime("%Y-%m-%d") || "n/a"
      puts format("%-25<k>s %<v>s", k: "Date:", v: date_str)
      puts format("%-25<k>s %<n>d (%<p>s pts)",
                  k: "Tasks:", n: tasks_count, p: total_pts)
      puts format("%-25<k>s %<v>d",
                  k: "Roster entries:", v: roster_count)
    end

    if campaign
      regs = campaign.user_registrations.count
      puts format("%-25<k>s %<v>s",
                  k: "Campaign status:", v: campaign.status)
      puts format("%-25<k>s %<v>d",
                  k: "Registrations:", v: regs)
    end

    puts "=" * 60
    puts "✅ Exam setup complete!"
  end

  desc "Reset exam playground (destroy exam + campaign)"
  task reset: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Exam Registration Campaign")

    if campaign
      campaign.update_column(:status, 0) # rubocop:disable Rails/SkipsModelValidations
      campaign.reload
      campaign.user_registrations.delete_all
      campaign.registration_items.delete_all
      exam&.exam_rosters&.delete_all
      campaign.delete
      puts "✓ Destroyed exam campaign + registrations"
    end

    if exam
      if exam.assessment
        pid = exam.assessment.assessment_participations.select(:id)
        Assessment::TaskPoint.where(assessment_participation_id: pid).delete_all
        exam.assessment.assessment_participations.delete_all
        exam.assessment.tasks.delete_all
        exam.assessment.delete
      end
      exam.delete
      puts "✓ Destroyed exam: Midterm Exam - Playground"
    end

    puts "Done."
  end

  desc "Reset only registrations (keeps exam + campaign)"
  task reset_registrations: :environment do
    lecture = Lecture.joins(:tutorials).distinct.first
    abort "No lecture with tutorials found." unless lecture

    campaign = Registration::Campaign.find_by(campaignable: lecture,
                                              description: "Exam Registration Campaign")
    abort "Campaign not found." unless campaign

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")

    campaign.user_registrations.destroy_all
    exam&.exam_rosters&.destroy_all

    campaign.update!(status: :open) if campaign.completed? || campaign.closed?

    puts "✓ Cleared registrations + roster. Campaign re-opened."
    puts "  Run exam:create_registrations to re-populate."
  end
end
