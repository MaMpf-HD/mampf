namespace :demo do
  desc "Set the feature flags relevant for the current slice"
  task set_relevant_feature_flags: :environment do
    Demo::SetupSupport.set_relevant_feature_flags!
  end

  desc "Run the legacy solver playground flow"
  task legacy_solver_playground: :environment do
    Demo::SetupSupport.setup_legacy_solver_playground!
  end

  task verify: :legacy_solver_playground

  desc "Create finalized lecture and seminar rosters for the assessment demo"
  task rosters: :environment do
    Demo::SetupSupport.setup_rosters!
  end

  desc "Create the maximum available demo data for the current slice"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end
end
