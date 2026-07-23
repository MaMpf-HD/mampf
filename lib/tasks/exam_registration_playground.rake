namespace :exam do
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
      puts "  Exam roster has #{exam.exam_roster_entries.count} entries."
      next
    end

    unless campaign.closed?
      campaign.update!(status: :closed)
      puts "✓ Closed campaign"
    end

    campaign.finalize!
    puts "✓ Finalized campaign — roster materialized"
    puts "  Exam roster: #{exam.exam_roster_entries.count} students"
  end

  desc "Run the registration scenario setup for playground exams"
  task setup_registration: :environment do
    Rake::Task["exam:create_campaign"].invoke
    Rake::Task["exam:create_registrations"].invoke
    Rake::Task["exam:finalize_campaign"].invoke
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
      exam.exam_roster_entries.destroy_all
      campaign.update!(status: :open) if campaign.completed? || campaign.closed?

      puts "✓ Cleared registrations for #{title}"
    end

    puts "Run exam:create_registrations to re-populate."
  end
end
