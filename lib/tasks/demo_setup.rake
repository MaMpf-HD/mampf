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

  desc "Create the maximum available demo data for the current slice"
  task setup: :environment do
    Demo::SetupSupport.setup!
  end

  desc "Stage the next-term banner scenario (flag, next term, demo lectures)"
  task next_term_banner: :environment do
    Demo::NextTermBannerSupport.setup!
  end
end
