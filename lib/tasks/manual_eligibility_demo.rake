namespace :eligibility_demo do
  EXAM_TITLE = "Prüfungszulassung Demo – Finale Zulassung"

  desc "Create an exam with a single student-performance policy " \
       "(checked at finalization only). " \
       "Set up a rule + certifications manually in the UI first."
  task setup: :environment do
    Flipper.enable(:assessment_grading)
    Flipper.enable(:registration_campaigns)
    Flipper.enable(:student_performance)

    Rake::Task["assessment:setup"].invoke
    Rake::Task["performance:compute"].invoke

    lecture = find_lecture!

    unless lecture.uses_exam_eligibility?
      abort "Lecture '#{lecture.title}' has uses_exam_eligibility disabled. " \
            "Enable it in the lecture preferences first."
    end

    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)
    if exam
      puts "✓ Exam already exists (ID: #{exam.id})"
    else
      exam = Exam.create!(
        lecture: lecture,
        title: EXAM_TITLE,
        date: 6.weeks.from_now,
        location: "Hörsaal 1",
        capacity: 200,
        description: "Demo exam. Policy: Prüfungszulassung required at finalization."
      )
      puts "✓ Created exam: #{exam.title} (ID: #{exam.id})"
    end

    campaign = exam.registration_campaign
    abort "Campaign not created. Is :registration_campaigns Flipper flag enabled?" unless campaign

    if campaign.registration_policies.where(kind: :student_performance).any?
      puts "✓ Performance policy already attached."
    else
      policy = Registration::Policy.new(
        registration_campaign: campaign,
        kind: :student_performance,
        phase: :finalization,
        active: true,
        config: {}
      )
      policy.lecture_id = lecture.id
      policy.save!
      puts "✓ Attached student-performance policy (finalization phase) " \
           "for lecture #{lecture.id}"
    end

    puts ""
    puts "=" * 60
    puts "Next steps:"
    puts "  1. In the UI: open the lecture → Assessments → Exam Eligibility tab"
    puts "     → create/activate a Rule, then review/adjust Certifications"
    puts "  2. Open the campaign from the Exam page (set a deadline and open it)"
    puts "  3. Have students register"
    puts "  4. Close and finalize the campaign"
    puts "     → the performance policy is checked at finalization only"
    puts "=" * 60
  end

  desc "Register all roster members of the lecture for the demo exam campaign"
  task register_members: :environment do
    Flipper.enable(:registration_campaigns)

    lecture = find_lecture!
    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)
    abort "Demo exam not found. Run eligibility_demo:setup first." unless exam

    campaign = exam.registration_campaign
    abort "No campaign found." unless campaign

    abort "Campaign is #{campaign.status}. Open it first." unless campaign.open? || campaign.draft?

    exam_item = campaign.registration_items
                        .find_by(registerable_type: "Exam")
    abort "No exam registration item found." unless exam_item

    member_ids = lecture.lecture_memberships.pluck(:user_id).uniq
    abort "No roster members found." if member_ids.empty?

    already = campaign.user_registrations.pluck(:user_id).to_set
    created = 0

    member_ids.each do |uid|
      next if already.include?(uid)

      Registration::UserRegistration.create!(
        user_id: uid,
        registration_campaign: campaign,
        registration_item: exam_item,
        status: :confirmed
      )
      created += 1
    end

    puts "✓ Registered #{created} roster members " \
         "(#{already.size} already existed)"
  end

  desc "Reset: destroy the demo exam and its campaign"
  task reset: :environment do
    Rake::Task["performance:reset"].invoke
    Rake::Task["assessment:reset"].invoke

    lecture = find_lecture!
    exam = Exam.find_by(lecture: lecture, title: EXAM_TITLE)

    unless exam
      puts "No demo exam found."
      next
    end

    campaign = exam.registration_campaign
    if campaign
      campaign.user_registrations.destroy_all
      campaign.registration_policies.each(&:delete)
      campaign.registration_items.destroy_all
      campaign.destroy!
      puts "✓ Destroyed campaign"
    end

    exam.exam_rosters.destroy_all
    exam.destroy!
    puts "✓ Destroyed exam: #{EXAM_TITLE}"
  end

  def find_lecture!
    lecture = Lecture.joins(:tutorials).distinct.first
    abort("No lecture with tutorials found. Run 'just seed' first.") unless lecture
    lecture
  end
end
