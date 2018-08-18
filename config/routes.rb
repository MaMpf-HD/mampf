Rails.application.routes.draw do

  get 'search/index'
  get '/administration', to: 'administration#index', as: 'administration'
  get '/administration/exit', to: 'administration#exit', as: 'exit_administration'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  resources :teachers, only: [:show]
  resources :courses
  resources :media, only: [:show, :index]
  resources :tags, only: [:show]
  resources :lessons, only: [:show]
  resources :sections, only: [:show]
  resources :chapters, only: [:show]
  resources :terms, except: [:show]
  get 'terms/cancel_term_edit', to: 'terms#cancel', as: 'cancel_term_edit'
  get 'search/index'

  get 'profile/edit', as: 'edit_profile'
  get 'courses/:course_id/food', to: 'media#index', as: 'course_food'
  post 'profile/update'
  get 'profile/check_for_consent', as: 'consent_profile'
  patch 'profile/add_consent', as: 'add_consent'
  put 'profile/add_consent'

  devise_for :users, controllers: { registrations: 'registrations' }
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
