Rails.application.routes.draw do

  get 'search/index'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  resources :teachers, only: [:show]
  resources :lectures, only: [:show]
  resources :courses, only: [:show]
  resources :media, only: [:show, :index]
  resources :tags, only: [:show]
  resources :lessons, only: [:show]
  resources :sections, only: [:show]
  resources :chapters, only: [:show]

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
