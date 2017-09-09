require 'rails_helper'

RSpec.describe Api::V1::MediaController, type: :controller do
  describe "GET #keks_question" do
    it "returns http success" do
      @keks_medium = FactoryGirl.create(:medium, sort: "KeksQuestion",
                                         question_id: 2567)
      get :keks_question, params: { id: @keks_medium.question_id }
      expect(response).to be_success
    end
    it "returns the correct video_link" do
      @keks_medium = FactoryGirl.create(:medium, sort: "KeksQuestion",
                                         question_id: 2567)
      get :keks_question, params: { id: @keks_medium.question_id }
      question_response = JSON.parse(response.body, symbolize_names: true)
      expect(question_response[:video_file_link]).to eql @keks_medium.video_file_link
    end
  end
end
