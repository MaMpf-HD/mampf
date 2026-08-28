namespace :seeds do
  desc "Rebuild the shipped development seed data " \
       "(term=\"WS 2026\" to move it there, the current term to rebuild in place, " \
       "default one semester on)"
  task build: :environment do
    Seeds::BuildSupport.build!(target_term: ENV.fetch("term", nil))
  end
end
