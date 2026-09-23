module E2e
  # Cleans the database for use in Playwright tests.
  class DatabaseCleanerController < BaseController
    def create
      res = retrying_deadlocks { DatabaseCleaner.clean_with(:truncation) }

      render json: res.to_json, status: :created
    end
  end
end
