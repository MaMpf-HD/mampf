require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns http success" do
      @tag = FactoryGirl.create(:tag, title: 'usual bs')
      get :show, params: { id: @tag.id }
      expect(response).to be_success
    end
  end

end
