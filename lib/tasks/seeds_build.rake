namespace :seeds do
  desc "Rebuild the shipped development seed data (one year on, demo material baked in)"
  task build: :environment do
    Seeds::BuildSupport.build!
  end
end
