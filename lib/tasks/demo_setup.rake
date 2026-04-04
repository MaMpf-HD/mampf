namespace :demo do
  desc "Enable feature flags and create all demo campaigns with registrations"
  task setup: :environment do
    puts "=== Demo Setup ==="
    puts ""

    puts "Enabling feature flags..."
    Flipper.enable(:roster_maintenance)
    Flipper.enable(:registration_campaigns)
    puts "  ✓ roster_maintenance"
    puts "  ✓ registration_campaigns"
    puts ""

    tasks = [
      ["solver:create_campaign", "solver:create_registrations"],
      ["solver:create_mixed_fcfs_campaign", "solver:create_mixed_fcfs_registrations"],
      ["solver:create_two_stage_campaign"]
    ]

    tasks.each do |group|
      group.each do |task_name|
        puts "Running #{task_name}..."
        Rake::Task[task_name].invoke
        Rake::Task[task_name].reenable
        puts ""
      end
    end

    puts "=== Demo setup complete ==="
  end
end
