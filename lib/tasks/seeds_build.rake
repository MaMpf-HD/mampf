namespace :seeds do
  desc "Rebuild the shipped development seed data (term=\"WS 2026\", default one semester on)"
  task build: :environment do
    Seeds::BuildSupport.build!(target_term: ENV.fetch("term", nil))
  end
end
