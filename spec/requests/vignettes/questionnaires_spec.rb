require 'rails_helper'

RSpec.describe "Vignettes::Questionnaires", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/vignettes/questionnaires/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/vignettes/questionnaires/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/vignettes/questionnaires/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/vignettes/questionnaires/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/vignettes/questionnaires/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/vignettes/questionnaires/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/vignettes/questionnaires/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
