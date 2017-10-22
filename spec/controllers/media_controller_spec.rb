require 'rails_helper'

RSpec.describe MediaController, type: :controller do

  before(:all) do
    FactoryGirl.create(:lecture) if Lecture.count == 0
    FactoryGirl.create(:medium) if Medium.count == 0
    @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    login_as @user
  end

  after(:all) do
    logout
  end

  # describe "GET #index" do
  #   it "returns http success" do
  #     get :index
  #     puts response.body
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  describe "GET #show" do
    it "returns http success" do
      get :show, params: { id: Medium.first.id }
      puts response.body
      expect(response).to have_http_status(:success)
    end
  end

end
