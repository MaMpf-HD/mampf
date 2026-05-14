namespace :demo do
  desc "Run the legacy registration and roster demo flow"
  task verify: :environment do
    Demo::SetupSupport.verify!
  end

  desc "Create finalized lecture and seminar rosters for the assessment demo"
  task rosters: :environment do
    Demo::SetupSupport.setup_rosters!
  end

  desc "Create the maximum available demo data for the current slice"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end
end
