Rails.application.routes.draw do

  get 'search/index'
  get '/administration', to: 'administration#index', as: 'administration'
  get '/administration/exit', to: 'administration#exit', as: 'exit_administration'
  get '/administration/profile', to: 'administration#profile', as: 'elevated_profile'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  resources :courses
  resources :media, only: [:show, :index]
  get 'tags/modal', to: 'tags#modal', as: 'tag_modal'
  get 'tags/:id/inspect/', to: 'tags#inspect', as: 'inspect_tag'
  resources :tags
  resources :lessons, only: [:show]
  get 'sections/reset/', to: 'sections#reset', as: 'reset_section' 
  resources :sections
  get 'chapters/:id/inspect/', to: 'chapters#inspect', as: 'inspect_chapter'
  resources :chapters
  resources :terms, except: [:show]
  get 'lectures/:id/inspect/', to: 'lectures#inspect', as: 'inspect_lecture'
  resources :lectures
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'users/elevate', to: 'users#elevate', as: 'elevate_user'
  get 'users/teacher/:teacher_id', to: 'users#teacher', as: 'teacher'
  resources :users, only: [:index, :edit, :update, :destroy]
  get 'terms/cancel_term_edit', to: 'terms#cancel', as: 'cancel_term_edit'
  get 'search/index'

  get 'profile/edit', as: 'edit_profile'
  get 'courses/:course_id/food', to: 'media#index', as: 'course_food'
  get 'courses/:id/inspect', to: 'courses#inspect', as: 'inspect_course'
  post 'profile/update'
  get 'profile/check_for_consent', as: 'consent_profile'
  patch 'profile/add_consent', as: 'add_consent'
  put 'profile/add_consent'

  root 'main#home'
  get 'about', to: 'main#about'
  get 'error', to: 'main#error'
  get 'main/home'
  get 'main/about'

  namespace :api do
    namespace :v1 do
      get 'tags', to: 'tags#index'
      get 'tags/:id', to: 'tags#show'
      get 'keks_questions/:id', to: 'media#keks_question'
    end
  end

  get '*path', to: 'main#error'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
