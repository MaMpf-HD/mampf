require 'rails_helper'

RSpec.describe AssetsController, type: :controller do

  describe "GET #show" do
    it "returns http success" do
      @asset = FactoryGirl.create(:asset)
      get :show, params: { id: @asset.id }
      expect(response).to have_http_status(:success)
    end
  end

end
