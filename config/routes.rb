Rails.application.routes.draw do

  get 'search/index'
  get '/administration', to: 'administration#index', as: 'administration'
  get '/administration/exit', to: 'administration#exit', as: 'exit_administration'
  get '/administration/profile', to: 'administration#profile', as: 'elevated_profile'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  resources :courses
  get 'media/search', to: 'media#search', as: 'media_search'
  get 'media/catalog', to: 'media#catalog', as: 'media_catalog'
  get 'media/:id/inspect/', to: 'media#inspect', as: 'inspect_medium'
  get 'media/:id/enrich', to: 'media#enrich', as: 'enrich_medium'
  resources :media, only: [:show, :index, :new, :edit, :update]
  get 'tags/modal', to: 'tags#modal', as: 'tag_modal'
  get 'tags/:id/inspect/', to: 'tags#inspect', as: 'inspect_tag'
  resources :tags
  get 'lessons/modal', to: 'lessons#modal', as: 'lesson_modal'
  get 'lessons/:id/inspect/', to: 'lessons#inspect', as: 'inspect_lesson'
  get 'lessons/list_sections/', to: 'lessons#list_sections', as: 'list_lesson_sections'
  resources :lessons, except: [:index]
  get 'sections/list_tags/', to: 'sections#list_tags', as: 'list_section_tags'
  get 'sections/list_lessons/', to: 'sections#list_lessons', as: 'list_section_lessons'
  resources :sections, except: [:index]
  get 'chapters/:id/inspect/', to: 'chapters#inspect', as: 'inspect_chapter'
  resources :chapters, except: [:index]
  resources :terms, except: [:show]
  get 'lectures/:id/inspect/', to: 'lectures#inspect', as: 'inspect_lecture'
  resources :lectures
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'users/elevate', to: 'users#elevate', as: 'elevate_user'
  get 'users/teacher/:teacher_id', to: 'users#teacher', as: 'teacher'
  resources :users, only: [:index, :edit, :update, :destroy]
  get 'terms/cancel_term_edit', to: 'terms#cancel', as: 'cancel_term_edit'

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
  mount ImageUploader.upload_endpoint(:cache) => "/images/upload"
  mount VideoUploader.upload_endpoint(:cache) => "/videos/upload"
  mount PdfUploader.upload_endpoint(:cache) => "/pdfs/upload"

  get '*path', to: 'main#error'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
