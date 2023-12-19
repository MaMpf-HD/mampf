namespace :mampf_setup do
  desc "This poulates the cache for mampf."
  task populate_cache: :environment do
    Medium.where.not(teachable: nil).map(&:scoped_teachable)
  end
end
