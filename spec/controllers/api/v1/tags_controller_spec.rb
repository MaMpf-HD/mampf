require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  describe '#index' do
    it 'returns http success' do
      get :index
      expect(response).to be_successful
    end
  end

  describe '#show' do
    before do
      @tag = FactoryBot.create(:tag)
    end
    it 'responds successfully' do
      get :show, params: { id: @tag.id }
      expect(response).to be_successful
    end
    it 'returns the correct tags' do
      get :show, params: { id: @tag.id }
      tag_response = JSON.parse(response.body, symbolize_names: true)
      expect(tag_response[:title]).to eql @tag.title
    end
  end
end
