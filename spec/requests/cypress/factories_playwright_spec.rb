require "rails_helper"

RSpec.describe("Cypress::FactoriesPlaywright", type: :request) do
  let(:params) { { factory_name: "term", traits: [] } }

  # A browser test's own page can still be finishing a request while the next
  # test asks for its records; the bridge has to survive that.
  it "asks again when the database picks its request to abort" do
    attempts = 0
    allow(FactoryBot).to receive(:create) do
      attempts += 1
      raise(ActiveRecord::Deadlocked, "deadlock detected") if attempts == 1

      Term.new(year: 2099, season: "SS")
    end

    post "/cypress/factories_playwright", params: params

    expect(response).to have_http_status(:created)
    expect(attempts).to eq(2)
  end

  it "leaves nothing behind from the attempt that was aborted" do
    attempts = 0
    allow(FactoryBot).to receive(:create) do
      attempts += 1
      # What a factory does before it saves the record itself.
      term = Term.create!(year: 2090 + attempts, season: "SS")
      raise(ActiveRecord::Deadlocked, "deadlock detected") if attempts == 1

      term
    end

    expect { post("/cypress/factories_playwright", params: params) }
      .to change(Term, :count).by(1)
  end

  it "gives up in the end, so a deadlock that stays is not hidden" do
    allow(FactoryBot).to receive(:create)
      .and_raise(ActiveRecord::Deadlocked, "deadlock detected")

    post "/cypress/factories_playwright", params: params

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["error"]).to include("Deadlocked")
  end
end
