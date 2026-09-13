require Rails.root.join("db/seeds/support/extract_support")

namespace :seeds do
  desc "Rebuild the shipped development seed data " \
       "(term=\"WS 2026\" to move it there, the current term to rebuild in place, " \
       "default one semester on)"
  task build: :environment do
    Seeds::BuildSupport.build!(target_term: ENV.fetch("term", nil))
  end

  desc "Write the content core of the seeded database out to db/seeds/data"
  task extract: :environment do
    Seeds::ExtractSupport.extract!.each do |row|
      skipped = row[:skipped].zero? ? "" : ", #{row[:skipped]} skipped"
      puts "#{row[:group]}: #{row[:written]} written#{skipped}"
    end
  end

  desc "Pack the uploads the seed data points at, for publishing beside the dump"
  task package: :environment do
    Seeds::PackageSupport.package!
  end
end
