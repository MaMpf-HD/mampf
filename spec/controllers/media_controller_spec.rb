require 'rails_helper'

RSpec.describe MediaController, type: :controller do

  describe "#index" do
    before do
      FactoryGirl.create(:lecture) if Lecture.count == 0
      FactoryGirl.create(:medium) if Medium.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "returns http success" do
      sign_in @user
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    before do
      FactoryGirl.create(:lecture) if Lecture.count == 0
      FactoryGirl.create(:medium) if Medium.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "returns http success" do
      sign_in @user
      get :show, params: { id: Medium.first.id }
      expect(response).to have_http_status(:success)
    end
  end

end
