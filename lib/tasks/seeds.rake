namespace :seeds do
  desc "Write the content core of the seeded database out to db/seeds/data"
  task extract: :environment do
    Seeds::ExtractSupport.extract!.each do |row|
      skipped = row[:skipped].zero? ? "" : ", #{row[:skipped]} skipped"
      puts "#{row[:group]}: #{row[:written]} written#{skipped}"
    end
  end

  desc "Pack the uploads the seed data points at, for publishing to mampf-init-data"
  task package: :environment do
    Seeds::PackageSupport.package!
  end

  desc "Check that a seeded database has everything db/seeds/ promises"
  task verify: :environment do
    results = Seeds::VerifySupport.verify!
    results.each { |r| puts "#{r[:ok] ? "✓" : "✗"} #{r[:check]} (#{r[:detail]})" }

    failures = results.reject { |r| r[:ok] }
    if failures.any?
      abort("\n#{failures.size} of #{results.size} checks failed.")
    else
      puts "\nAll #{results.size} checks passed."
    end
  end
end
