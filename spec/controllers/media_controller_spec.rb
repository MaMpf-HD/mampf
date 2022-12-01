# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaController, type: :controller do
  # NEEDS TO BE REFACTORED

  describe '#search_by' do
    before :all do
      Medium.destroy_all
      
      # create a medium with title test1
      # @medium1 = FactoryBot.create(:medium, title: 'Test1')
      # # create a medium with a teacher
      # @medium2 = FactoryBot.create(:medium, :with_editors, editors_count: 1)
      # # create a medium with a tag
      # @medium3 = FactoryBot.create(:medium, :with_tags, tags_count: 1)
      # # create a medium of type quiz belonging to a lecture
      # @medium4 = FactoryBot.create(:medium, :with_teachable, teachable_sort: :lecture, sort: :quiz)

      Medium.reindex
      
      @user = FactoryBot.create(:confirmed_user)
      
    end

    it 'should find a medium by title' do

      # login user
      sign_in @user


      get :search, params: { search: 'Test1' }
      puts response.body
      assert_equal "TEST", assigns(:test)
      expect(assigns(:media)).to include(@media)
    end
  end

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
