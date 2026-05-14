namespace :demo do
  desc "Create demo assignments, tasks, participations, statuses, and points"
  task assessment: :environment do
    Demo::SetupSupport.setup_assessment!
  end
end
