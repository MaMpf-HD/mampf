# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  # NEEDS TO BE REFACTORED

  # describe '#index' do

  #   before do
  #     course = FactoryBot.create(:course, :with_tags)
  #     lecture = FactoryBot.create(:lecture, course: course)
  #     @tag = lecture.tags.first
  #   end

  #   context 'as an authenticated user' do
  #     before do
  #       @user = FactoryBot.create(:user, subscription_type: 2)
  #     end

  #     it 'responds successfully' do
  #       sign_in @user
  #       get :index, params: { search: @tag.title }
  #       expect(response).to be_successful
  #     end

  #     it 'returns a 200 response' do
  #       sign_in @user
  #       get :index, params: { search: @tag.title }
  #       expect(response).to have_http_status '200'
  #     end

  #     context 'with render views' do
  #       render_views

  #       it 'returns a match statement if there is a match' do
  #         sign_in @user
  #         get :index, params: { search: @tag.title }
  #         expect(response.body).to include 'hat 1 Treffer ergeben'
  #       end

  #       it 'returns a no-match statement if there is no match' do
  #         sign_in @user
  #         get :index, params: { search: 'xdsgdte' }
  #         expect(response.body).to include 'hat 0 Treffer ergeben'
  #       end
  #     end
  #   end

  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       get :index, params: { search: @tag.title }
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the sign-in page' do
  #       get :index, params: { search: @tag.title }
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end
  # end
end
