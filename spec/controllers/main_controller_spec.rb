# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MainController, type: :controller do
  # NEEDS TO BE REFACTORED

  # describe '#home' do
  #   it 'responds successfully' do
  #     get :home
  #     expect(response).to be_successful
  #   end

  #   it 'returns a 200 response' do
  #     get :home
  #     expect(response).to have_http_status '200'
  #   end
  # end

  # describe '#about' do
  #   it 'responds successfully' do
  #     get :about
  #     expect(response).to be_successful
  #   end

  #   it 'returns a 200 response' do
  #     get :about
  #     expect(response).to have_http_status '200'
  #   end
  # end

  # describe '#error' do
  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       get :error
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the sign-in page' do
  #       get :error
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end

  #   context 'as an authenticated user' do
  #     before do
  #       @user = FactoryBot.create(:user)
  #     end

  #     it 'returns a 302 response' do
  #       sign_in @user
  #       get :error
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the root page' do
  #       sign_in @user
  #       get :error
  #       expect(response).to redirect_to root_path
  #     end
  #   end
  # end
end
