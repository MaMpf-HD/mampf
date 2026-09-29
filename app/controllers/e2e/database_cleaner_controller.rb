module E2e
  # Cleans the database for use in Playwright tests. Clears the cache too: the
  # rate limits count there, and a test run again within the hour would
  # otherwise be refused by the counts of the runs before it.
  class DatabaseCleanerController < BaseController
    def create
      res = retrying_deadlocks { DatabaseCleaner.clean_with(:truncation) }
      Rails.cache.clear

      render json: res.to_json, status: :created
    end
  end
end
