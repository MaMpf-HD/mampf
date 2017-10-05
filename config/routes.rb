Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  resources :teachers, only: [:show, :index]
  resources :lectures, only: [:show, :index]
  resources :courses, only: [:show]
  resources :media, only: [:show, :index]
  resources :tags, only: [:show]
  resources :lessons, only: [:show]
  resources :sections, only: [:show]
  resources :chapters, only: [:show]  

  get 'profile/edit', as: 'edit_profile'
  get 'lectures/:lecture_id/modules/:module_id', to: 'media#index', as: 'lecture_module'

  patch 'profile/update'
  put 'profile/update'

  devise_for :users, controllers: { registrations: 'registrations' }
  root 'main#home'
  get 'about', to: 'main#about'
  get 'main/home'
  get 'main/about'

  namespace :api do
    namespace :v1 do
      get 'tags', to: 'tags#index'
      get 'tags/:id', to: 'tags#show'
      get 'keks_questions/:id', to: 'media#keks_question'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
