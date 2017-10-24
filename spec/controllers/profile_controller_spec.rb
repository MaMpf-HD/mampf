require 'rails_helper'

RSpec.describe ProfileController, type: :controller do

  describe "#edit" do
    before do
      FactoryGirl.create(:lecture) if Lecture.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "returns http success" do
      sign_in @user
      get :edit
      expect(response).to have_http_status(:success)
    end
  end

  describe "#update" do
    before do
      FactoryGirl.create(:lecture) if Lecture.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "redirects to the main page" do
      sign_in @user
      patch :update, params: { user: {lecture_ids: ['1'], subscription_type: '2' } }
      expect(response).to redirect_to root_path
    end
  end

end
