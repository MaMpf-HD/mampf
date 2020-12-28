# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaController, type: :controller do
  # NEEDS TO BE REFACTORED

  # describe '#index' do
  #   before do
  #     FactoryBot.create(:medium)
  #   end
  #   context 'as an authenticated user' do
  #     before do
  #       @user = FactoryBot.create(:user)
  #     end

  #     it 'redirects to root_page if no param is given' do
  #       sign_in @user
  #       get :index
  #       expect(response).to redirect_to root_path
  #     end

  #     it 'redirects to the root_page if course_id param is nonsense' do
  #       sign_in @user
  #       course = FactoryBot.create(:course)
  #       id = course.id + 1
  #       get :index, params: { course_id: id.to_s }
  #       expect(response).to redirect_to root_path
  #     end

  #     it 'redirects to the root_page if project param is nonsense' do
  #       sign_in @user
  #       course = FactoryBot.create(:course)
  #       get :index, params: { course_id: course.id.to_s, project: 'bs' }
  #       expect(response).to redirect_to root_path
  #     end

  #     it 'redirects to the given module if deactivated for lecture' do
  #       sign_in @user
  #       course = FactoryBot.create(:course)
  #       get :index, params: { course_id: course.id.to_s, project: 'kaviar' }
  #       expect(response).to redirect_to root_path
  #     end

  #     it 'returns a 200 response if lecture_id and module_id make sense' do
  #       sign_in @user
  #       course = FactoryBot.create(:course)
  #       FactoryBot.create(:medium, teachable: course, sort: 'Kaviar')
  #       get :index, params: { course_id: course.id.to_s, project: 'kaviar' }
  #       expect(response).to have_http_status '200'
  #     end
  #   end

  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       get :index
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the sign-in page' do
  #       get :index
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end
  # end

  # describe '#show' do
  #   before do
  #     @medium = FactoryBot.create(:medium)
  #   end
  #   context 'as an authenticated user' do
  #     before do
  #       @user = FactoryBot.create(:user)
  #     end
  #     it 'responds successfully' do
  #       sign_in @user
  #       get :show, params: { id: @medium.id }
  #       expect(response).to be_successful
  #     end

  #     it 'returns a 200 response' do
  #       sign_in @user
  #       get :show, params: { id: @medium.id }
  #       expect(response).to have_http_status '200'
  #     end
  #   end

  #   context 'as an unauthenticated user' do
  #     it 'returns a 302 response' do
  #       get :show, params: { id: @medium.id }
  #       expect(response).to have_http_status '302'
  #     end

  #     it 'redirects to the sign-in page' do
  #       get :show, params: { id: @medium.id }
  #       expect(response).to redirect_to user_session_path
  #     end
  #   end
  # end
end
