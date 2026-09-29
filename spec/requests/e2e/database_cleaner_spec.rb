require "rails_helper"

RSpec.describe("E2e::DatabaseCleaner", type: :request) do
  # The truncation waits for a lock that the previous test's page still holds,
  # and Postgres picks one of the two to abort.
  it "asks again when the database picks its request to abort" do
    attempts = 0
    allow(DatabaseCleaner).to receive(:clean_with) do
      attempts += 1
      raise(ActiveRecord::Deadlocked, "deadlock detected") if attempts == 1

      []
    end

    post "/e2e/database_cleaner"

    expect(response).to have_http_status(:created)
    expect(attempts).to eq(2)
  end

  it "gives up in the end, so a deadlock that stays is not hidden" do
    allow(DatabaseCleaner).to receive(:clean_with)
      .and_raise(ActiveRecord::Deadlocked, "deadlock detected")

    post "/e2e/database_cleaner"

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["error"]).to include("Deadlocked")
  end

  # The rate limits count in the cache, and a test run again within the hour
  # must not be refused by the runs before it.
  it "clears the cache along with the database" do
    allow(DatabaseCleaner).to receive(:clean_with).and_return([])
    Rails.cache.write("rate-limit:support_requests:signed_out:127.0.0.1", 5)

    post "/e2e/database_cleaner"

    expect(Rails.cache.read("rate-limit:support_requests:signed_out:127.0.0.1")).to be_nil
  end
end
