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
end
