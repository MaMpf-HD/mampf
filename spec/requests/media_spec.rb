require "rails_helper"

RSpec.describe("Media", type: :request) do
  # Use an admin to bypass visibility filters for simplicity
  let(:user) do
    create(:confirmed_user, admin: true)
  end
  let!(:medium_ruby) { create(:valid_medium, description: "An introduction to Ruby") }
  let!(:medium_python) { create(:valid_medium, description: "A guide to Python") }

  before do
    sign_in user
  end

  describe "GET /media/search" do
    it "returns a successful response" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response).to have_http_status(:ok)
    end

    it "returns the correct media in the response body" do
      get search_media_path, params: { search: { fulltext: "Ruby" } }, xhr: true
      expect(response.body).to include(medium_ruby.description)
      expect(response.body).not_to include(medium_python.description)
    end
  end
end
