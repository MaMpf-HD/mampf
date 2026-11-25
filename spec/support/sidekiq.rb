# Sidekiq jobs enqueued in specs are only collected in memory instead of being
# pushed to Redis, where a running development Sidekiq would pick them up and
# run them against the wrong database.
Sidekiq.testing!(:fake)

RSpec.configure do |config|
  config.before do
    Sidekiq::Job.clear_all
  end
end
