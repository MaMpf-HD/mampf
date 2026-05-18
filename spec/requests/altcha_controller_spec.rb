require "rails_helper"

RSpec.describe("Altcha", type: :request) do
  describe "GET /altcha" do
    before do
      Rails.cache.clear
    end

    it "returns a successful response with a challenge" do
      get "/altcha"
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("algorithm")
      expect(json_response).to have_key("challenge")
      expect(json_response).to have_key("salt")
      expect(json_response).to have_key("signature")
    end

    context "rate limiting" do
      it "blocks requests over the limit" do
        # Ensure cache is cleared or use a fresh IP
        Rails.cache.clear

        # 15 allowed requests
        15.times do |_i|
          get "/altcha"
          expect(response).to have_http_status(:ok)
        end

        # next request should be blocked
        get "/altcha"
        expect(response).to have_http_status(:too_many_requests)
        expect(JSON.parse(response.body)["error"]).to eq("Rate limit exceeded")
      end
    end
  end
end
