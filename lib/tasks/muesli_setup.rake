namespace :muesli do
  desc "Full Müsli arena setup (demo + solver finalize + exams + assessments + performance + policy)"
  task setup: :environment do
    abort "Cannot run in production!" if Rails.env.production?

    puts ""
    puts "=" * 60
    puts "  Müsli Arena Setup"
    puts "=" * 60
    puts ""

    enable_feature_flags

    run_task("demo:setup")
    finalize_solver_campaign
    run_task("playground:setup")
    run_task("exam_policy:setup")

    puts ""
    puts "=" * 60
    puts "  Müsli Arena Setup Complete"
    puts "=" * 60
    puts ""
    puts "  Feature flags enabled:"
    puts "    ✓ roster_maintenance"
    puts "    ✓ registration_campaigns"
    puts "    ✓ assessment_grading"
    puts "    ✓ student_performance"
    puts ""
    puts "  What was created:"
    puts "    • Solver Test Campaign (finalized)"
    puts "    • Cohort FCFS Campaign"
    puts "    • Two-stage Seminar Campaign"
    puts "    • 3 Exams (midterm finalized, practice open, final draft)"
    puts "    • 10 Homework assignments with tasks + grades"
    puts "    • Performance records"
    puts "    • Policy exam scenario (email + performance policies)"
    puts ""
  end

  desc "Reset all Müsli arena data"
  task reset: :environment do
    abort "Cannot run in production!" if Rails.env.production?

    puts "Resetting Müsli arena..."

    run_task("exam_policy:reset")
    run_task("playground:reset")

    puts "Done."
  end

  def enable_feature_flags
    puts "Enabling feature flags..."
    [:roster_maintenance, :registration_campaigns, :assessment_grading,
     :student_performance].each do |flag|
      Flipper.enable(flag)
      puts "  ✓ #{flag}"
    end
    puts ""
  end

  def finalize_solver_campaign
    puts "-" * 60
    puts "Finalizing Solver Test Campaign..."
    puts "-" * 60

    campaign = Registration::Campaign
               .find_by(description: "Solver Test Campaign")
    abort("Solver Test Campaign not found. demo:setup may have failed.") unless campaign

    if campaign.completed?
      puts "  ✓ Already finalized."
      return
    end

    unless campaign.closed?
      campaign.update!(status: :closed)
      puts "  ✓ Closed campaign"
    end

    if campaign.preference_based?
      service = Registration::AllocationService.new(campaign)
      service.allocate!
      puts "  ✓ Ran allocation solver"
    end

    campaign.finalize!
    puts "  ✓ Finalized — roster materialized"

    lecture = campaign.campaignable
    memberships = TutorialMembership.where(tutorial_id: lecture.tutorial_ids).count
    puts "  ✓ #{memberships} tutorial memberships created"
    puts ""
  end

  def run_task(name)
    puts "-" * 60
    puts "Running #{name}..."
    puts "-" * 60
    Rake::Task[name].invoke
    Rake::Task[name].reenable
    puts ""
  end
end
