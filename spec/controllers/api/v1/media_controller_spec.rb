require 'rails_helper'

RSpec.describe Api::V1::MediaController, type: :controller do
  describe '#keks_question' do
    before do
      @keks_medium = FactoryBot.create(:medium, sort: 'Question',
                                                 question_id: 2567)
    end
    it 'responds_successfully' do
      get :keks_question, params: { id: @keks_medium.question_id }
      expect(response).to be_successful
    end
    it 'returns a 200 response' do
      get :keks_question, params: { id: @keks_medium.question_id }
      expect(response).to have_http_status '200'
    end
    it 'returns the correct video_link' do
      get :keks_question, params: { id: @keks_medium.question_id }
      question_response = JSON.parse(response.body, symbolize_names: true)
      expect(question_response[:medium][:video_file_link])
        .to eql @keks_medium.video_file_link
    end
  end
end
