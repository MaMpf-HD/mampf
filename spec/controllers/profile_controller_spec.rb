require 'rails_helper'

RSpec.describe ProfileController, type: :controller do

  before(:all) do
    FactoryGirl.create(:lecture) if Lecture.count == 0
    @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    login_as @user
  end

  after(:all) do
    logout
  end

  describe "GET #edit" do
    it "returns http success" do
      get :edit
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #update" do
    it "returns http success" do
      patch :update
      expect(response).to have_http_status(:success)
    end
  end

end
