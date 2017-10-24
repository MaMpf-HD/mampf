require 'rails_helper'

RSpec.describe CoursesController, type: :controller do

  describe "#show" do
    before do
      FactoryGirl.create(:lecture) if Lecture.count == 0
      FactoryGirl.create(:course) if Course.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "returns http success" do
      sign_in @user
      get :show, params: { id: Course.first.id }
      expect(response).to have_http_status(:success)
    end
  end

end
