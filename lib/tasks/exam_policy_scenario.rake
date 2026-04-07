namespace :exam_policy do
  EXAM_TITLE = "Policy Exam - Finalization Scenario".freeze
  EMAIL_DOMAIN = "example.com".freeze
  NUM_OUTSIDERS = 5

  desc "Full setup: exam + policies + registrations + certifications"
  task setup: :environment do
    old_level = ActiveRecord::Base.logger&.level
    ActiveRecord::Base.logger&.level = :warn

    Rake::Task["exam_policy:create_exam"].invoke
    Rake::Task["exam_policy:create_policies"].invoke
    Rake::Task["exam_policy:register_students"].invoke
    Rake::Task["exam_policy:open_campaign"].invoke
    Rake::Task["exam_policy:issue_certifications"].invoke

    ActiveRecord::Base.logger&.level = old_level
    print_summary
  end

  desc "Create the exam"
  task create_exam: :environment do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)

    lecture = find_lecture!
    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)

    if exam
      puts "✓ Exam already exists: #{EXAM_TITLE} (ID: #{exam.id})"
    else
      exam = Exam.create!(
        lecture: lecture,
        title: EXAM_TITLE,
        date: 4.weeks.from_now,
        location: "Exam Hall C",
        capacity: 100,
        description: "Exam with email + performance policies for finalization testing."
      )
      puts "✓ Created exam: #{EXAM_TITLE} (ID: #{exam.id})"
    end
  end

  desc "Attach email (both phases) + student performance (finalization only) policies"
  task create_policies: :environment do
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:student_performance)

    exam = find_exam!
    campaign = exam.registration_campaign
    abort "No campaign found for exam." unless campaign

    unless campaign.draft?
      puts "⚠ Campaign is #{campaign.status}; policies can only be added in draft."
      puts "  Run exam_policy:reset first if you want to recreate."
      next
    end

    if campaign.registration_policies.any?
      puts "✓ Policies already exist (#{campaign.registration_policies.count}). Skipping."
      next
    end

    Registration::Policy.create!(
      registration_campaign: campaign,
      kind: :institutional_email,
      phase: :both,
      active: true,
      config: { "allowed_domains" => EMAIL_DOMAIN }
    )
    puts "✓ Added email policy: @#{EMAIL_DOMAIN} (checked on both phases)"

    lecture = exam.lecture
    Registration::Policy.create!(
      registration_campaign: campaign,
      kind: :student_performance,
      phase: :finalization,
      active: true,
      config: { "lecture_id" => lecture.id }
    )
    puts "✓ Added performance policy: lecture #{lecture.id} (finalization only)"
  end

  desc "Register students (tutorial members + outsiders with wrong domain)"
  task register_students: :environment do
    Flipper.enable(:registration_campaigns)

    exam = find_exam!
    campaign = exam.registration_campaign
    abort "No campaign." unless campaign

    exam_item = campaign.registration_items
                        .find_by(registerable_type: "Exam")
    abort "No exam item in campaign." unless exam_item

    existing = campaign.user_registrations.count
    if existing.positive?
      puts "✓ #{existing} registrations already exist. Skipping."
      next
    end

    lecture = exam.lecture
    member_ids = TutorialMembership.where(tutorial_id: lecture.tutorial_ids)
                                   .pluck(:user_id).uniq

    abort "No tutorial members. Run solver:create_campaign + finalize first." if member_ids.empty?

    registered = 0
    member_ids.each do |uid|
      next if rand > 0.85

      FactoryBot.create(:registration_user_registration,
                        user_id: uid,
                        registration_campaign: campaign,
                        registration_item: exam_item,
                        status: :confirmed)
      registered += 1
    end
    puts "✓ Registered #{registered} tutorial members (@#{EMAIL_DOMAIN})"

    outsider_count = 0
    NUM_OUTSIDERS.times do |i|
      email = "outsider_#{i + 1}@other-university.de"
      user = User.find_by(email: email)
      user ||= FactoryBot.create(:confirmed_user,
                                 email: email,
                                 name: "Outsider Student #{i + 1}")

      FactoryBot.create(:registration_user_registration,
                        user_id: user.id,
                        registration_campaign: campaign,
                        registration_item: exam_item,
                        status: :confirmed)
      outsider_count += 1
    end
    puts "✓ Registered #{outsider_count} outsiders (@other-university.de)"
    puts "  → These will FAIL the email policy on finalization"
  end

  desc "Open the campaign"
  task open_campaign: :environment do
    Flipper.enable(:registration_campaigns)

    exam = find_exam!
    campaign = exam.registration_campaign
    abort "No campaign." unless campaign

    if campaign.draft?
      if campaign.registration_deadline &&
         campaign.registration_deadline < Time.current
        campaign.update!(registration_deadline: 1.week.from_now, status: :open)
      else
        campaign.update!(status: :open)
      end
      puts "✓ Opened campaign"
    else
      puts "✓ Campaign already #{campaign.status}"
    end
  end

  desc "Issue certifications: some pass, some fail the performance check"
  task issue_certifications: :environment do
    ActiveRecord::Base.logger&.level = :warn
    Flipper.enable(:student_performance)

    exam = find_exam!
    lecture = exam.lecture
    campaign = exam.registration_campaign
    abort "No campaign." unless campaign

    teacher = User.find_by(email: "teacher@mampf.edu")
    abort "Teacher not found. Run 'just seed' first." unless teacher

    rule = StudentPerformance::Rule.find_by(lecture: lecture, active: true)
    unless rule
      puts "⚠ No active performance rule. Run performance:compute first."
      puts "  Skipping certification step."
      next
    end

    confirmed_user_ids = campaign.user_registrations
                                 .where(status: :confirmed)
                                 .pluck(:user_id).uniq

    example_com_ids = User.where(id: confirmed_user_ids)
                          .where("email LIKE ?", "%@#{EMAIL_DOMAIN}")
                          .pluck(:id)

    if example_com_ids.empty?
      puts "⚠ No @#{EMAIL_DOMAIN} registrations found. Skipping."
      next
    end

    shuffled = example_com_ids.shuffle
    pass_count = (shuffled.size * 0.45).ceil
    fail_count = (shuffled.size * 0.25).ceil
    pending_count = (shuffled.size * 0.10).ceil
    passers = shuffled.first(pass_count)
    failers = shuffled[pass_count, fail_count]
    pending_users = shuffled[pass_count + fail_count, pending_count]
    # remaining = uncertified (no cert at all)
    uncertified = shuffled[(pass_count + fail_count + pending_count)..]

    created = 0
    skipped = 0

    passers.each do |uid|
      cert = StudentPerformance::Certification
             .find_or_initialize_by(lecture: lecture, user_id: uid)
      if cert.persisted? && !cert.pending?
        skipped += 1
        next
      end
      cert.update!(status: :passed, source: :manual,
                   certified_by: teacher, certified_at: Time.current,
                   rule: rule)
      created += 1
    end

    failers.each do |uid|
      cert = StudentPerformance::Certification
             .find_or_initialize_by(lecture: lecture, user_id: uid)
      if cert.persisted? && !cert.pending?
        skipped += 1
        next
      end
      cert.update!(status: :failed, source: :manual,
                   certified_by: teacher, certified_at: Time.current,
                   rule: rule)
      created += 1
    end

    pending_users.each do |uid|
      cert = StudentPerformance::Certification
             .find_or_initialize_by(lecture: lecture, user_id: uid)
      if cert.persisted? && !cert.pending?
        skipped += 1
        next
      end
      cert.update!(status: :pending, source: :computed,
                   rule: rule)
      created += 1
    end

    puts "✓ Issued #{created} certifications (skipped #{skipped} existing)"
    puts "  #{passers.size} passed, #{failers.size} failed,"
    puts "  #{pending_users.size} pending, #{uncertified.size} uncertified"
    puts "  → Failed: trip performance policy (override or remove)"
    puts "  → Pending: need decision before finalization"
    puts "  → Uncertified: need 'Compute now' on dashboard"
  end

  desc "Reset: destroy exam + campaign + outsiders + certifications"
  task reset: :environment do
    lecture = find_lecture!
    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)

    if exam
      campaign = exam.registration_campaign
      if campaign
        campaign.user_registrations.destroy_all
        campaign.registration_policies.each { |p| p.delete }
        campaign.registration_items.destroy_all
        campaign.destroy!
        puts "✓ Destroyed campaign + registrations"
      end
      exam.exam_rosters.destroy_all
      exam.destroy!
      puts "✓ Destroyed exam: #{EXAM_TITLE}"
    else
      puts "No exam found."
    end

    outsiders = User.where("email LIKE ?", "outsider_%@other-university.de")
    puts "✓ Removed #{outsiders.delete_all} outsider users"

    certs = StudentPerformance::Certification.where(
      lecture: lecture, source: :manual
    )
    puts "✓ Removed #{certs.delete_all} manual certifications"
  end

  def find_lecture!
    lecture = Lecture.joins(:tutorials).distinct.first
    abort("No lecture with tutorials found.") unless lecture
    lecture
  end

  def find_exam!
    lecture = find_lecture!
    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)
    abort("Exam '#{EXAM_TITLE}' not found. Run exam_policy:create_exam first.") unless exam
    exam
  end

  def print_summary
    exam = find_exam!
    campaign = exam.registration_campaign
    lecture = exam.lecture

    regs = campaign&.user_registrations&.count || 0
    policies = campaign&.registration_policies&.count || 0
    example_regs = campaign&.user_registrations
                           &.joins(:user)
                           &.where("users.email LIKE ?", "%@#{EMAIL_DOMAIN}")
                           &.count || 0
    outsider_regs = campaign&.user_registrations
                            &.joins(:user)
                            &.where("users.email LIKE ?",
                                    "%@other-university.de")
                            &.count || 0
    certs = StudentPerformance::Certification
            .where(lecture: lecture,
                   user_id: campaign&.user_registrations&.pluck(:user_id))

    puts "\n#{"=" * 60}"
    puts "Policy Exam Scenario Summary"
    puts "=" * 60
    puts "  Exam:       #{exam.title} (#{exam.date})"
    puts "  Campaign:   #{campaign&.status || "none"}"
    puts "  Policies:   #{policies}"
    puts "  Registrations: #{regs} total"
    puts "    @#{EMAIL_DOMAIN}: #{example_regs}"
    puts "    @other-university.de: #{outsider_regs} (will fail email policy)"
    puts "  Certifications: #{certs.passed.count} passed, " \
         "#{certs.failed.count} failed " \
         "(#{certs.where(status: :pending).count} pending)"
    puts ""
    puts "  Next steps (manual in UI):"
    puts "    1. Go to the exam → Registration tab"
    puts "    2. Close the campaign"
    puts "    3. Click 'Review & Finalize'"
    puts "    4. The guard will show policy violations:"
    puts "       - Outsiders failing the email policy"
    puts "       - @#{EMAIL_DOMAIN} students who failed performance"
    puts "    5. Choose to force-finalize or go back and fix"
    puts "=" * 60
  end
end
