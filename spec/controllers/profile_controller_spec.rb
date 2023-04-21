# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileController, type: :controller do
  # NEEDS TO BE REFACTORED

  # describe '#edit' do
  #   context 'as an authenticated user' do
  #     before do
  #       @user = FactoryBot.create(:user)
  #     end

  #     it 'responds successfully' do
  #       sign_in @user
  #       get :edit
  #       expect(response).to be_successful
  #     end

  #     it 'returns a 200 response' do
  #       sign_in @user
  #       get :edit
  #       expect(response).to have_http_status '200'
  #     end
  #   end
  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       get :edit
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the sign-in page' do
  #       get :edit
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end
  # end

  # describe '#update' do
  #   before do
  #     @lecture = FactoryBot.create(:lecture)
  #   end
  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       patch :update, params: { user: { lecture_ids: [@lecture.id.to_s],
  #                                        subscription_type: '2' } }
  #       expect(response).to have_http_status '302'
  #     end
  #     it 'redirects to the sign-in page' do
  #       patch :update, params: { user: { lecture_ids: [@lecture.id.to_s],
  #                                        subscription_type: '2' } }
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end
  # end
end
