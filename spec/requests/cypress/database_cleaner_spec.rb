require "rails_helper"

RSpec.describe("Cypress::DatabaseCleaner", type: :request) do
  # The truncation waits for a lock that the previous test's page still holds,
  # and Postgres picks one of the two to abort.
  it "asks again when the database picks its request to abort" do
    attempts = 0
    allow(DatabaseCleaner).to receive(:clean_with) do
      attempts += 1
      raise(ActiveRecord::Deadlocked, "deadlock detected") if attempts == 1

      []
    end

    post "/cypress/database_cleaner"

    expect(response).to have_http_status(:created)
    expect(attempts).to eq(2)
  end

  it "gives up in the end, so a deadlock that stays is not hidden" do
    allow(DatabaseCleaner).to receive(:clean_with)
      .and_raise(ActiveRecord::Deadlocked, "deadlock detected")

    post "/cypress/database_cleaner"

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["error"]).to include("Deadlocked")
  end
end
