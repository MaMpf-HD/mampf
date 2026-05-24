require "rails_helper"

RSpec.describe("UploadRoutes", type: :request) do
  [
    "/screenshots/upload",
    "/profile_image/upload",
    "/videos/upload",
    "/pdfs/upload",
    "/ggbs/upload",
    "/submissions/upload",
    "/corrections/upload",
    "/packages/upload"
  ].each do |path|
    it "redirects anonymous requests for #{path}" do
      post path

      expect(response).to have_http_status(:found)
      expect(response.headers["Location"]).to eq("http://www.example.com/users/sign_in")
    end
  end
end
