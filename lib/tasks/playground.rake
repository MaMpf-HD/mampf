namespace :playground do
  desc "Run full playground setup (exam + assessment)"
  task setup: :environment do
    Rake::Task["exam:setup"].invoke
    Rake::Task["assessment:setup"].invoke
  end

  desc "Reset full playground (assessment + exam)"
  task reset: :environment do
    Rake::Task["assessment:reset"].invoke
    Rake::Task["exam:reset"].invoke
  end

  desc "Reset and re-setup full playground"
  task redo: :environment do
    Rake::Task["playground:reset"].invoke
    Rake::Task["playground:setup"].invoke
  end
end
