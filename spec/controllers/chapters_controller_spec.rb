require 'rails_helper'

RSpec.describe ChaptersController, type: :controller do

  describe "#show" do
    before do
      FactoryGirl.create(:chapter) if Chapter.count == 0
      @user = FactoryGirl.create(:user, lectures: Lecture.all, sign_in_count: 5)
    end
    it "returns http success" do
      sign_in @user
      get :show, params: { id: Chapter.first.id }
      expect(response).to have_http_status(:success)
    end
  end

end
