require 'rails_helper'

RSpec.describe ProfileController, type: :controller do

  before(:all) do
    @user = User.create
    login_as @user, scope: :user
  end

  describe "GET #edit" do
    it "returns http success" do
      get :edit
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #update" do
    it "returns http success" do
      get :update
      expect(response).to have_http_status(:success)
    end
  end

end
