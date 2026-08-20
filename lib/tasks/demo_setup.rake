namespace :demo do
  desc "Create reusable campaign playground scenarios"
  task campaigns: :environment do
    Demo::SetupSupport.setup_campaigns!
  end

  desc "Create finalized lecture and seminar rosters for the assessment demo"
  task rosters: :environment do
    Demo::SetupSupport.setup_rosters!
  end

  desc "Create demo assignments, tasks, participations, statuses, and points"
  task assessment: :environment do
    Demo::SetupSupport.setup_assessment!
  end

  desc "Create demo achievements and performance records"
  task performance: :environment do
    Demo::SetupSupport.setup_performance!
  end

  desc "Create an active eligibility rule and certify the demo students against it"
  task eligibility: :environment do
    Demo::SetupSupport.setup_eligibility!
  end

  desc "Create demo exams with campaigns, registrations and a finalized roster"
  task exams: :environment do
    Demo::SetupSupport.setup_exams!
  end

  desc "Grade the finalized demo exam by applying a banded grading scheme"
  task grading: :environment do
    Demo::SetupSupport.setup_grading!
  end

  desc "Create the maximum available demo data for the current slice"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end

  desc "Stage the next-term banner scenario (flag, next term, demo lectures)"
  task next_term_banner: :environment do
    Demo::NextTermBannerSupport.setup!
  end
end
