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
#   bundle exec rake exam:setup    # Full setup
#   bundle exec rake exam:reset    # Start over

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

  desc "Open/manage registration campaigns for the exams"
  task create_campaign: :environment do
    Flipper.enable(:registration_campaigns)

    lecture = find_lecture!

    midterm = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    practice = Exam.find_by(lecture: lecture,
                            title: "Practice Exam - Open Registration")

    [midterm, practice].compact.each do |exam|
      campaign = exam.registration_campaign
      next unless campaign

      if campaign.draft?
        if campaign.registration_deadline < Time.current
          campaign.update!(registration_deadline: 1.week.from_now,
                           status: :open)
        else
          campaign.update!(status: :open)
        end
        puts "✓ Opened campaign for #{exam.title}"
      else
        puts "✓ Campaign for #{exam.title} already #{campaign.status}"
      end
    end

    final_exam = Exam.find_by(lecture: lecture, title: "Final Exam - Draft")
    puts "✓ Campaign for #{final_exam.title} stays draft" if final_exam&.registration_campaign
  end

  desc "Create user registrations for the exam campaigns"
  task create_registrations: :environment do
    lecture = find_lecture!

    midterm = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    practice = Exam.find_by(lecture: lecture,
                            title: "Practice Exam - Open Registration")

    user_ids = TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
                                 .pluck(:user_id).uniq

    if user_ids.empty?
      abort "No tutorial members found. Run solver:create_campaign + " \
            "solver:create_registrations first, then finalize that campaign."
    end

    register_users(midterm, user_ids, ratio: 0.9)
    register_users(practice, user_ids, ratio: 0.5)
  end

  desc "Finalize the midterm campaign (materialize roster)"
  task finalize_campaign: :environment do
    lecture = find_lecture!

    exam = Exam.find_by(lecture: lecture, title: "Midterm Exam - Playground")
    abort "Midterm exam not found." unless exam

    campaign = exam.registration_campaign
    abort "Campaign not found." unless campaign

    if campaign.completed?
      puts "✓ Campaign already finalized."
      puts "  Exam roster has #{exam.exam_rosters.count} entries."
      next
    end

    unless campaign.closed?
      campaign.update!(status: :closed)
      puts "✓ Closed campaign"
    end

    campaign.finalize!
    puts "✓ Finalized campaign — roster materialized"
    puts "  Exam roster: #{exam.exam_rosters.count} students"
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
      roster = exam.exam_rosters.count

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

  desc "Reset only registrations (keeps exams + campaigns)"
  task reset_registrations: :environment do
    lecture = find_lecture!

    playground_titles.each do |title|
      exam = Exam.find_by(lecture: lecture, title: title)
      next unless exam

      campaign = exam.registration_campaign
      next unless campaign

      campaign.user_registrations.destroy_all
      exam.exam_rosters.destroy_all
      campaign.update!(status: :open) if campaign.completed? || campaign.closed?

      puts "✓ Cleared registrations for #{title}"
    end

    puts "Run exam:create_registrations to re-populate."
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
      exam.exam_rosters.delete_all
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
end
