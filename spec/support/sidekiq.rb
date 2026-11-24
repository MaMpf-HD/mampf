require "sidekiq/testing"

# Sidekiq jobs enqueued in specs are only collected in memory instead of being
# pushed to Redis, where a running development Sidekiq would pick them up and
# run them against the wrong database.
Sidekiq::Testing.fake!

RSpec.configure do |config|
  config.before do
    Sidekiq::Worker.clear_all
  end
end
