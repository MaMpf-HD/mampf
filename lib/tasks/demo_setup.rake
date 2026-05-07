namespace :demo do
  desc "Run the legacy registration and roster demo flow"
  task verify: :environment do
    Demo::SetupSupport.verify!
  end

  desc "Create finalized lecture and seminar rosters for the assessment demo"
  task rosters: :environment do
    Demo::SetupSupport.setup_rosters!
  end

  desc "Create demo assignments, tasks, participations, statuses, and points"
  task assessment: :environment do
    Demo::SetupSupport.setup_assessment!
  end

  desc "Create rosters and assessment demo data in one pass"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end
end
