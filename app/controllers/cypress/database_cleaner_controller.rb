module Cypress
  # Cleans the database for use in Cypress tests.
  class DatabaseCleanerController < CypressController
    def create
      res = DatabaseCleaner.clean_with(:truncation)

      render json: res.to_json, status: :created
    end
  end
end
