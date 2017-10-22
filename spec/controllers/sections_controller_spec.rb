require 'rails_helper'

RSpec.describe SectionsController, type: :controller do

  before(:all) do
    FactoryGirl.create(:lecture) if Lecture.count == 0
    FactoryGirl.create(:section) if Section.count == 0
    @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    login_as @user
  end

  after(:all) do
    logout
  end

  describe "GET #show" do
    it "returns http success" do
      get :show, params: { id: Section.first.id }
      expect(response).to have_http_status(:success)
    end
  end

end
