require "rails_helper"

RSpec.describe("Health", type: :request) do
  describe "GET /up" do
    it "returns ok" do
      get "/up"

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /ready" do
    let(:readiness_check) { instance_double(ReadinessCheck) }

    before do
      allow(ReadinessCheck).to receive(:new).and_return(readiness_check)
    end

    it "returns ok when all dependencies are ready" do
      allow(readiness_check).to receive(:call).and_return(
        database: "ok",
        redis: "ok",
        memcached: "ok"
      )

      get "/ready"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        "status" => "ok",
        "checks" => {
          "database" => "ok",
          "redis" => "ok",
          "memcached" => "ok"
        }
      )
    end

    it "returns service unavailable when a dependency is down" do
      allow(readiness_check).to receive(:call).and_return(
        database: "ok",
        redis: "error",
        memcached: "ok"
      )

      get "/ready"

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)).to eq(
        "status" => "error",
        "checks" => {
          "database" => "ok",
          "redis" => "error",
          "memcached" => "ok"
        }
      )
    end
  end
end