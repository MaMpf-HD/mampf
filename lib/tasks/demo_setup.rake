namespace :demo do
  desc "Set the feature flags relevant for the current slice"
  task flags: :environment do
    Demo::SetupSupport.setup_flags!
  end

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

  desc "Create the maximum available demo data for the current slice"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end
end
