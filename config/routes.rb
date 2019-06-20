Rails.application.routes.draw do

  get 'search/index'

  get '/administration', to: 'administration#index',
                         as: 'administration'
  get '/administration/exit', to: 'administration#exit',
                              as: 'exit_administration'
  get '/administration/profile', to: 'administration#profile',
                                 as: 'elevated_profile'

  resources :announcements, only: [ :index, :new, :create]

  resources :answers, except: [:index, :show, :edit]

  get 'chapters/:id/list_sections', to: 'chapters#list_sections',
                                     as: 'list_sections'
  resources :chapters, except: [:index, :show]

  get 'courses/:course_id/food', to: 'media#index',
                                 as: 'course_food'
  get 'courses/:id/inspect', to: 'courses#inspect',
                             as: 'inspect_course'
  get 'courses/:id/display', to: 'courses#display',
                             as: 'display_course'
  get 'courses/:id/show_random_quizzes', to: 'courses#show_random_quizzes',
                                         as: 'show_random_quizzes'
  get 'courses/:id/take_random_quiz', to: 'courses#take_random_quiz',
                                      as: 'random_quiz'
  resources :courses, except: [:index]

  get 'events/update_vertex_default', as: 'update_vertex_default'
  get 'events/update_branching', as: 'update_branching'
  get 'events/new_vertex_quizzables', as: 'new_vertex_quizzables'
  get 'events/new_vertex_quizzable_text', as: 'new_vertex_quizzable_text'
  get 'events/update_vertex_body', as: 'update_vertex_body'
  get 'events/update_answer_body', as: 'update_answer_body'
  get 'events/update_answer_box', as: 'update_answer_box'
  get 'events/cancel_question_basics', as: 'cancel_question_basics'
  get 'events/cancel_remark_basics', as: 'cancel_remark_basics'
  get 'events/cancel_quiz_basics', as: 'cancel_quiz_basics'
  get 'events/fill_quizzable_modal', as: 'fill_quizzable_modal'
  get 'events/fill_reassign_modal', as: 'fill_reassign_modal'
  get 'events/render_tag_title', as: 'render_tag_title'

  get 'items/:id/display', to: 'items#display',
                           as: 'display_item'
  resources :items, only: [:update, :create, :edit, :destroy]

  get 'lectures/:id/inspect', to: 'lectures#inspect',
                               as: 'inspect_lecture'
  get 'lectures/:id/update_teacher', to: 'lectures#update_teacher',
                                      as: 'update_teacher'
  get 'lectures/:id/update_editors', to: 'lectures#update_editors',
                                      as: 'update_editors'
  get 'lectures/:id/add_forum', to: 'lectures#add_forum',
                                as: 'add_forum'
  get 'lectures/:id/lock_forum', to: 'lectures#lock_forum',
                                 as: 'lock_forum'
  get 'lectures/:id/unlock_forum', to: 'lectures#unlock_forum',
                                 as: 'unlock_forum'
  get 'lectures/:id/destroy_forum', to: 'lectures#destroy_forum',
                                 as: 'destroy_forum'
  get 'lectures/:id/render_sidebar', to: 'lectures#render_sidebar',
                                     as: 'render_sidebar'
  get 'lectures/:id/show_announcements', to: 'lectures#show_announcements',
                                         as: 'show_announcements'
  get 'lectures/:id/organizational', to: 'lectures#organizational',
                                         as: 'organizational'
  post 'lecture/:id/publish', to: 'lectures#publish',
                            as: 'publish_lecture'

  resources :lectures, except: [:index]

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
  post 'media/:id/publish', to: 'media#publish',
                            as: 'publish_medium'
  post 'media/:id/import_manuscript', to: 'media#import_manuscript',
                                      as: 'import_manuscript'
  resources :media

  post 'notifications/destroy_all', to: 'notifications#destroy_all',
                                    as: 'destroy_all_notifications'
  post 'notifications/destroy_lecture_notifications',
       to: 'notifications#destroy_lecture_notifications',
       as: 'destroy_lecture_notifications'
  post 'notifications/destroy_news_notifications',
       to: 'notifications#destroy_news_notifications',
       as: 'destroy_news_notifications'
  resources :notifications, only: [:index, :destroy]

  get 'profile/edit', as: 'edit_profile'
  post 'profile/update'
  get 'profile/check_for_consent', as: 'consent_profile'
  patch 'profile/add_consent', as: 'add_consent'
  put 'profile/add_consent'

  patch 'questions/:id/reassign', to: 'questions#reassign',
                                  as: 'reassign_question'
  resources :questions, only: [:edit, :update]

  get 'quizzes/:id/take', to: 'quizzes#take',
                          as: 'take_quiz'
  patch 'quizzes/:id/take', to: 'quizzes#proceed'
  put 'quizzes/:id/take', to: 'quizzes#proceed'
  get 'quizzes/:id/preview', to: 'quizzes#preview',
                             as: 'preview_quiz'

  resources :quizzes, except: [:show, :index, :create]  do
    resources :vertices, except: [:index, :show, :edit]
  end

  get 'referrals/list_items', to: 'referrals#list_items',
                              as: 'list_items'
  resources :referrals, only: [:update, :create, :edit, :destroy]

  patch 'remarks/:id/reassign', to: 'remarks#reassign',
                                as: 'reassign_remark'
  resources :remarks, only: [:edit, :update]

  get 'tags/modal', to: 'tags#modal',
                    as: 'tag_modal'
  get 'tags/:id/inspect', to: 'tags#inspect',
                           as: 'inspect_tag'
  get 'tags/:id/display_cyto', to: 'tags#display_cyto',
                                as: 'display_cyto_tag'
  patch 'tags/:id/identify', to: 'tags#identify',
                            as: 'identify_tags'
  put 'tags/:id/identify', to: 'tags#identify'
  resources :tags

  get 'sections/list_tags', to: 'sections#list_tags',
                             as: 'list_section_tags'
  get 'sections/:id/display', to: 'sections#display',
                              as: 'display_section'
  resources :sections, except: [:index]

  get 'terms/cancel_term_edit', to: 'terms#cancel',
                                as: 'cancel_term_edit'
  resources :terms, except: [:show]

  devise_for :users, controllers: { registrations: 'registrations' }
  get 'users/elevate', to: 'users#elevate',
                       as: 'elevate_user'
  get 'users/teacher/:teacher_id', to: 'users#teacher',
                                   as: 'teacher'
  get 'users/list_generic_users', to: 'users#list_generic_users',
                                  as: 'list_generic_users'
  resources :users, only: [:index, :edit, :update, :destroy]

  root 'main#home'
  get 'error', to: 'main#error'
  get 'main/home'
  get 'main/news', to: 'main#news',
                   as: 'news'

  mount ScreenshotUploader.upload_endpoint(:cache) => "/screenshots/upload"
  mount VideoUploader.upload_endpoint(:cache) => "/videos/upload"
  mount PdfUploader.upload_endpoint(:cache) => "/pdfs/upload"
  mount Thredded::Engine => '/forum'
  get '*path', to: 'main#error'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
