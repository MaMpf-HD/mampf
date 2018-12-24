Rails.application.routes.draw do

  get 'search/index'

  get '/administration', to: 'administration#index',
                         as: 'administration'
  get '/administration/exit', to: 'administration#exit',
                              as: 'exit_administration'
  get '/administration/profile', to: 'administration#profile',
                                 as: 'elevated_profile'

  resources :announcements, only: [ :index, :new, :create]

  get 'chapters/:id/list_sections', to: 'chapters#list_sections',
                                     as: 'list_sections'
  resources :chapters, except: [:index, :show]

  get 'courses/:course_id/food', to: 'media#index',
                                 as: 'course_food'
  get 'courses/:id/inspect', to: 'courses#inspect',
                             as: 'inspect_course'
  resources :courses, except: [:index]

  get 'items/:id/display', to: 'items#display',
                           as: 'display_item'
  resources :items, only: [:update, :create, :edit, :destroy]

  get 'lectures/:id/inspect', to: 'lectures#inspect',
                               as: 'inspect_lecture'
  get 'lectures/:id/update_teacher', to: 'lectures#update_teacher',
                                      as: 'update_teacher'
  get 'lectures/:id/update_editors', to: 'lectures#update_editors',
                                      as: 'update_editors'
  resources :lectures, except: [:index, :show]

  get 'lessons/:id/inspect', to: 'lessons#inspect',
                             as: 'inspect_lesson'
  resources :lessons, except: [:index]

  get 'media/search', to: 'media#search',
                      as: 'media_search'
  get 'media/catalog', to: 'media#catalog',
                       as: 'media_catalog'
  get 'media/delete_destinations', to: 'media#delete_destinations',
                                   as: 'delete_destinations'
  get 'media/:id/inspect', to: 'media#inspect',
                            as: 'inspect_medium'
  get 'media/:id/enrich', to: 'media#enrich',
                          as: 'enrich_medium'
  get 'media/:id/play', to: 'media#play',
                        as: 'play_medium'
  get 'media/:id/display', to: 'media#display',
                           as: 'display_medium'
  get 'media/:id/add_item', to: 'media#add_item',
                            as: 'add_item'
  get 'media/:id/add_reference', to: 'media#add_reference',
                                 as: 'add_reference'
  get 'media/:id/export_toc', to: 'media#export_toc',
                              as: 'export_toc'
  get 'media/:id/export_references', to: 'media#export_references',
                                     as: 'export_references'
  get 'media/:id/export_screenshot', to: 'media#export_screenshot',
                                     as: 'export_screenshot'
  patch 'media/:id/remove_screenshot', to: 'media#remove_screenshot',
                                       as: 'remove_screenshot'
  post 'media/:id/add_screenshot', to: 'media#add_screenshot',
                                   as: 'add_screenshot'
  resources :media

  post 'notifications/destroy_all', to: 'notifications#destroy_all',
                                    as: 'destroy_all_notifications'
  resources :notifications, only: [:index, :destroy]

  get 'referrals/list_items', to: 'referrals#list_items',
                              as: 'list_items'
  resources :referrals, only: [:update, :create, :edit, :destroy]

  get 'tags/modal', to: 'tags#modal',
                    as: 'tag_modal'
  get 'tags/:id/inspect/', to: 'tags#inspect',
                           as: 'inspect_tag'
  get 'tags/:id/display_cyto/', to: 'tags#display_cyto',
                                as: 'display_cyto_tag'
  resources :tags

  get 'sections/list_tags/', to: 'sections#list_tags', as: 'list_section_tags'
  resources :sections, except: [:index]
  resources :terms, except: [:show]
  devise_for :users, controllers: { registrations: 'registrations' }
  get 'users/elevate', to: 'users#elevate', as: 'elevate_user'
  get 'users/teacher/:teacher_id', to: 'users#teacher', as: 'teacher'
  get 'users/list_generic_users', to: 'users#list_generic_users', as: 'list_generic_users'
  resources :users, only: [:index, :edit, :update, :destroy]
  get 'terms/cancel_term_edit', to: 'terms#cancel', as: 'cancel_term_edit'

  get 'profile/edit', as: 'edit_profile'
  post 'profile/update'
  get 'profile/check_for_consent', as: 'consent_profile'
  patch 'profile/add_consent', as: 'add_consent'
  put 'profile/add_consent'

  root 'main#home'
  get 'about', to: 'main#about'
  get 'error', to: 'main#error'
  get 'main/home'
  get 'main/about'
  get 'main/news', to: 'main#news',
                   as: 'news'

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
