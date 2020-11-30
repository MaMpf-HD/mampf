Rails.application.routes.draw do

  require 'sidekiq/web'

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  mount Commontator::Engine => '/commontator'

  get 'search/index'

  get '/administration', to: 'administration#index',
                         as: 'administration'
  get '/administration/exit', to: 'administration#exit',
                              as: 'exit_administration'
  get '/administration/profile', to: 'administration#profile',
                                 as: 'elevated_profile'
  get '/administration/classification', to: 'administration#classification',
                                        as: 'classification'

  post 'announcements/:id/propagate', to: 'announcements#propagate',
                                      as: 'propagate_announcement'
  post 'announcements/:id/expel', to: 'announcements#expel',
                                  as: 'expel_announcement'
  resources :announcements, only: [ :index, :new, :create]

  resources :answers, except: [:index, :show, :edit]

  resources :areas, except: [:show]

  get 'assignments/:id/cancel_edit', to: 'assignments#cancel_edit',
                                   as: 'cancel_edit_assignment'
  get 'assignments/cancel_new', to: 'assignments#cancel_new',
                              as: 'cancel_new_assignment'

  resources :assignments, only: [ :new, :edit, :create, :update, :destroy]

  get 'chapters/:id/list_sections', to: 'chapters#list_sections',
                                     as: 'list_sections'
  resources :chapters, except: [:index, :show]

  get 'clickers/:id/open', to: 'clickers#open',
                           as: 'open_clicker'
  get 'clickers/:id/close', to: 'clickers#close',
                            as: 'close_clicker'
  post 'clickers/:id/set_alternatives', to: 'clickers#set_alternatives',
                                        as: 'set_clicker_alternatives'
  post 'clickers/:id/associate_question', to: 'clickers#associate_question',
                                          as: 'associate_question'
  get 'clickers/:id/get_votes_count', to: 'clickers#get_votes_count',
                                      as: 'get_votes_count'
  delete 'clickers/:id/remove_question', to: 'clickers#remove_question',
                                        as: 'remove_question'

  resources :clickers, except: [:index, :update]

  resources :clicker_votes, only: :create

  get 'c/:id', to: 'clickers#show'

  get 'courses/:id/inspect', to: 'courses#inspect',
                             as: 'inspect_course'
  post 'courses/:id/take_random_quiz', to: 'courses#take_random_quiz',
                                      as: 'random_quiz'
  get 'courses/:id/render_question_counter', to: 'courses#render_question_counter',
                                             as: 'render_question_counter'
  resources :courses, except: [:index, :show]

  resources :divisions, except: [:show]

  get 'events/update_vertex_default', as: 'update_vertex_default'
  get 'events/update_branching', as: 'update_branching'
  get 'events/update_vertex_body', as: 'update_vertex_body'
  get 'events/update_answer_body', as: 'update_answer_body'
  get 'events/update_answer_box', as: 'update_answer_box'
  get 'events/cancel_question_basics', as: 'cancel_question_basics'
  get 'events/cancel_remark_basics', as: 'cancel_remark_basics'
  get 'events/cancel_quiz_basics', as: 'cancel_quiz_basics'
  get 'events/fill_quizzable_area', as: 'fill_quizzable_area'
  get 'events/fill_reassign_modal', as: 'fill_reassign_modal'
  get 'events/render_tag_title', as: 'render_tag_title'
  get 'events/fill_quizzable_preview', as: 'fill_quizzable_preview'
  get 'events/fill_medium_preview', as: 'fill_medium_preview'
  get 'events/render_import_vertex', as: 'render_import_vertex'
  get 'events/render_vertex_quizzable', as: 'render_vertex_quizzable'
  get 'events/edit_vertex_targets', as: 'edit_vertex_targets'
  get 'events/cancel_import_vertex', as: 'cancel_import_vertex'
  get 'events/render_medium_actions', as: 'render_medium_actions'
  get 'events/render_medium_tags', as: 'render_medium_tags'
  get 'events/render_clickerizable_actions', as: 'render_clickerizable_actions'
  get 'events/cancel_solution_edit', as: 'cancel_solution_edit'
  get 'events/texify_solution', as: 'texify_solution'
  get 'events/render_question_parameters', as: 'render_question_parameters'
  get 'events/render_import_media', as: 'render_import_media'
  get 'events/cancel_import_media', as: 'cancel_import_media'

  get 'interactions/export_interactions', as: 'export_interactions'
  get 'interactions/export_probes', as: 'export_probes'

  resources :interactions, only: [:index]

  get 'items/:id/display', to: 'items#display',
                           as: 'display_item'
  resources :items, only: [:update, :create, :edit, :destroy]

  get 'lectures/:id/food', to: 'media#index',
                           as: 'lecture_food'
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
  get 'lectures/:id/show_announcements', to: 'lectures#show_announcements',
                                         as: 'show_announcements'
  get 'lectures/:id/organizational', to: 'lectures#organizational',
                                         as: 'organizational'
  get 'lectures/:id/show_random_quizzes', to: 'lectures#show_random_quizzes',
                                         as: 'show_random_quizzes'
  get 'lectures/:id/show_subscribers', to: 'lectures#show_subscribers',
                                       as: 'show_subscribers'
  get 'lectures/:id/show_structures', to: 'lectures#show_structures',
                                      as: 'show_structures'
  get 'lectures/:id/edit_structures', to: 'lectures#edit_structures',
                                      as: 'edit_structures'
  get 'lectures/:id/search_examples', to: 'lectures#search_examples',
                                      as: 'search_examples'
  get 'lectures/search', to: 'lectures#search',
                         as: 'search_lectures'
  get 'lectures/:id/display_course', to: 'lectures#display_course',
                                     as: 'display_course'
  post 'lectures/:id/publish', to: 'lectures#publish',
                              as: 'publish_lecture'
  post 'lectures/:id/import_media', to: 'lectures#import_media',
                                    as: 'lecture_import_media'
  delete 'lectures/:id/remove_imported_medium',
         to: 'lectures#remove_imported_medium',
         as: 'lecture_remove_imported_medium'
  get 'lectures/:id/close_comments', to: 'lectures#close_comments',
                                     as: 'lecture_close_comments'
  get 'lectures/:id/open_comments', to: 'lectures#open_comments',
                                     as: 'lecture_open_comments'
  get 'lectures/:id/submissions', to: 'submissions#index',
                                  as: 'lecture_submissions'
  get 'lectures/:id/tutorials', to: 'tutorials#index',
                                as: 'lecture_tutorials'
  get 'lectures/:id/tutorial_overview', to: 'tutorials#overview',
                                        as: 'lecture_tutorial_overview'

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
  get 'media/:id/geogebra', to: 'media#geogebra',
                            as: 'geogebra_medium'
  get 'media/:id/add_item', to: 'media#add_item',
                            as: 'add_item'
  get 'media/:id/add_reference', to: 'media#add_reference',
                                 as: 'add_reference'
  get 'media/:id/export_toc', to: 'media#export_toc',
                              as: 'export_toc'
  get 'media/:id/import_script_items', to: 'media#import_script_items',
                                       as: 'import_script_items'
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
  get 'media/fill_teachable_select', to: 'media#fill_teachable_select',
                                     as: 'fill_teachable_select'
  get 'media/fill_media_select', to: 'media#fill_media_select',
                                     as: 'fill_media_select'
  post 'media/update_tags', to: 'media#update_tags',
                            as: 'update_tags'
  post 'media/:id/register_download', to: 'media#register_download',
                                      as: 'register_download'
  get 'media/:id/get_statistics', to: 'media#get_statistics',
                                  as: 'get_statistics'
  get 'media/:id/show_comments', to: 'media#show_comments',
                                 as: 'show_media_comments'
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
  post 'profile/toggle_thread_subscription', as: 'toggle_thread_subscription'
  patch 'profile/subscribe_lecture', as: 'subscribe_lecture'
  patch 'profile/unsubscribe_lecture', as: 'unsubscribe_lecture'
  get 'profile/show_accordion', as: 'show_accordion'
  patch 'profile/star_lecture', as: 'star_lecture'
  patch 'profile/unstar_lecture', as: 'unstar_lecture'


  resources :programs, except: [:show]

  patch 'questions/:id/reassign', to: 'questions#reassign',
                                  as: 'reassign_question'
  patch 'question/:id/set_solution_type', to: 'questions#set_solution_type',
                                          as: 'set_solution_type'
  resources :questions, only: [:edit, :update]

  post 'quiz_certificates/:id/claim', to: 'quiz_certificates#claim',
                                     as: 'claim_quiz_certificate'

  post 'quiz_certificates/validate', to: 'quiz_certificates#validate',
                                     as: 'validate_certificate'

  get 'quizzes/:id/take', to: 'quizzes#take',
                          as: 'take_quiz'
  patch 'quizzes/:id/take', to: 'quizzes#proceed'
  put 'quizzes/:id/take', to: 'quizzes#proceed'
  get 'quizzes/:id/preview', to: 'quizzes#preview',
                             as: 'preview_quiz'
  patch 'quizzes/:id/linearize', to: 'quizzes#linearize',
                                 as: 'linearize_quiz'
  post 'quizzes/:id/set_root', to: 'quizzes#set_root',
                               as: 'set_quiz_root'
  post 'quizzes/:id/set_level', to: 'quizzes#set_level',
                                 as: 'set_quiz_level'
  post 'quizzes/:id/update_default_target', to: 'quizzes#update_default_target',
                                            as: 'update_default_target'
  delete 'quizzes/:id/delete_edge', to: 'quizzes#delete_edge',
                                            as: 'delete_edge'
  resources :quizzes, except: [:show, :index, :create]  do
    resources :vertices, except: [:index, :show, :edit]
  end

  patch 'readers/update', to: 'readers#update',
                           as: 'update_reader'

  patch 'readers/update_all', to: 'readers#update_all',
                              as: 'update_all_readers'

  get 'referrals/list_items', to: 'referrals#list_items',
                              as: 'list_items'
  resources :referrals, only: [:update, :create, :edit, :destroy]

  patch 'remarks/:id/reassign', to: 'remarks#reassign',
                                as: 'reassign_remark'
  resources :remarks, only: [:edit, :update]

  resources :subjects, except: [:show]

  post 'submissions/join', to: 'submissions#join',
                            as: 'join_submission'
  get 'submissions/enter_code', to: 'submissions#enter_code',
                                as: 'enter_submission_code'
  get 'submissions/redeem_code', to: 'submissions#redeem_code',
                                 as: 'redeem_submission_code'

  delete 'submissions/:id/leave', to: 'submissions#leave',
                                  as: 'leave_submission'
  get 'submissions/:id/cancel_edit', to: 'submissions#cancel_edit',
                                   as: 'cancel_edit_submission'
  get 'submissions/cancel_new', to: 'submissions#cancel_new',
                              as: 'cancel_new_submission'
  get 'submissions/:id/show_manuscript', to: 'submissions#show_manuscript',
                                         as: 'show_submission_manuscript'
  patch 'submissions/:id/refresh_token', to: 'submissions#refresh_token',
                                         as: 'refresh_submission_token'
  get 'submissions/:id/enter_invitees', to: 'submissions#enter_invitees',
                                        as: 'enter_submission_invitees'
  post 'submissions/:id/invite', to: 'submissions#invite',
                                 as: 'invite_to_submission'
  post 'submissions/:id/add_correction', to: 'submissions#add_correction',
                                         as: 'add_correction'
  get 'submissions/:id/show_correction', to: 'submissions#show_correction',
                                         as: 'show_correction'
  get 'submissions/:id/select_tutorial', to: 'submissions#select_tutorial',
                                         as: 'select_tutorial'
  patch 'submissions/:id/move', to: 'submissions#move',
                              as: 'move_submission'
  get 'submissions/:id/cancel_action', to: 'submissions#cancel_action',
                                         as: 'cancel_submission_action'

  delete 'submissions/:id/delete_correction',
         to: 'submissions#delete_correction',
         as: 'delete_correction'

  patch 'submissions/:id/accept', to: 'submissions#accept',
                                  as: 'accept_submission'

  patch 'submissions/:id/reject', to: 'submissions#reject',
                                  as: 'reject_submission'

  get 'submissions/:id/edit_correction', to: 'submissions#edit_correction',
                                         as: 'edit_correction'

  get 'submissions/:id/cancel_edit_correction',
      to: 'submissions#cancel_edit_correction',
      as: 'cancel_edit_correction'

  resources :submissions, except: [:index, :show]

  get 'tags/modal', to: 'tags#modal',
                    as: 'tag_modal'
  get 'tags/:id/inspect', to: 'tags#inspect',
                           as: 'inspect_tag'
  get 'tags/:id/display_cyto', to: 'tags#display_cyto',
                                as: 'display_cyto_tag'
  patch 'tags/:id/identify', to: 'tags#identify',
                            as: 'identify_tags'
  put 'tags/:id/identify', to: 'tags#identify'
  get 'tags/fill_tag_select', to: 'tags#fill_tag_select',
                              as: 'fill_tag_select'
  get 'events/fill_course_tags', to: 'tags#fill_course_tags',
                                 as: 'fill_course_tags'
  get 'tags/search', to: 'tags#search',
                      as: 'tags_search'
  get 'tags/:id/take_random_quiz', to: 'tags#take_random_quiz',
                                   as: 'tag_random_quiz'
  post 'tags/postprocess', to: 'tags#postprocess',
                           as: 'postprocess_tags'
  resources :tags

  get 'tutorials/:id/cancel_edit', to: 'tutorials#cancel_edit',
                                   as: 'cancel_edit_tutorial'
  get 'tutorials/cancel_new', to: 'tutorials#cancel_new',
                              as: 'cancel_new_tutorial'

  get 'tutorials/:id/assignments/:ass_id/bulk_download',
      to: 'tutorials#bulk_download',
      as: 'bulk_download_submissions'

  patch 'tutorials/:id/assignments/:ass_id/bulk_upload',
        to: 'tutorials#bulk_upload',
        as: 'bulk_upload_corrections'

  get 'tutorials/validate_certificate',
      to: 'tutorials#validate_certificate',
      as: 'validate_certificate_as_tutor'

  get 'tutorials/:id/assignments/:ass_id/export_teams',
      to: 'tutorials#export_teams',
      as: 'export_teams_to_csv'

  resources :tutorials, only: [ :new, :edit, :create, :update, :destroy]

  get 'sections/list_tags', to: 'sections#list_tags',
                             as: 'list_section_tags'
  get 'sections/:id/display', to: 'sections#display',
                              as: 'display_section'
  resources :sections, except: [:index]

  get 'terms/cancel_term_edit', to: 'terms#cancel',
                                as: 'cancel_term_edit'
  post 'terms/set_active_term', to: 'terms#set_active',
                                as: 'set_active_term'
  resources :terms, except: [:show]

  devise_for :users, controllers: { confirmations: 'confirmations',
                                    registrations: 'registrations',
                                    sessions: 'sessions' }

  get 'users/elevate', to: 'users#elevate',
                       as: 'elevate_user'
  get 'users/teacher/:teacher_id', to: 'users#teacher',
                                   as: 'teacher'
  get 'users/list_generic_users', to: 'users#list_generic_users',
                                  as: 'list_generic_users'
  get 'users/fill_user_select', to: 'users#fill_user_select',
                              as: 'fill_user_select'
  get 'users/list', to: 'users#list',
                    as: 'list_users'
  get 'users/delete_account', to: 'users#delete_account',
                              as: 'delete_account'
  resources :users, only: [:index, :edit, :update, :destroy]

  get 'examples/:id', to: 'erdbeere#show_example',
                      as: 'erdbeere_example'
  post 'examples/find', to: 'erdbeere#find_example'
  get 'properties/:id', to: 'erdbeere#show_property',
                        as: 'erdbeere_property'
  get 'structures/:id', to: 'erdbeere#show_structure',
                        as: 'erdbeere_structure'
  get 'find_erdbeere_tags', to: 'erdbeere#find_tags',
                            as: 'find_erdbeere_tags'
  post 'update_erdbeere_tags', to: 'erdbeere#update_tags',
                            as: 'update_erdbeere_tags'
  get 'edit_erdbeere_tags', to: 'erdbeere#edit_tags',
                            as: 'edit_erdbeere_tags'
  get 'cancel_edit_erdbeere_tags', to: 'erdbeere#cancel_edit_tags',
                            as: 'cancel_edit_erdbeere_tags'
  get 'display_erdbeere_info', to: 'erdbeere#display_info',
                            as: 'display_erdbeere_info'
  get 'fill_realizations_select', to: 'erdbeere#fill_realizations_select',
                                  as: 'fill_realizations_select'

  root 'main#home'
  get 'error', to: 'main#error'
  get 'main/home'
  get 'main/news', to: 'main#news',
                   as: 'news'
  get 'main/comments', to: 'main#comments',
                       as: 'comments'
  get 'main/sponsors', to: 'main#sponsors',
                       as: 'sponsors'
  get 'main/start', to: 'main#start',
                    as: 'start'

  mount ScreenshotUploader.upload_endpoint(:cache) => "/screenshots/upload"
  mount VideoUploader.upload_endpoint(:cache) => "/videos/upload"
  mount PdfUploader.upload_endpoint(:cache) => "/pdfs/upload"
  mount GeogebraUploader.upload_endpoint(:cache) => "/ggbs/upload"
  mount SubmissionUploader.upload_endpoint(:submission_cache) => "/submissions/upload"
  mount CorrectionUploader.upload_endpoint(:submission_cache) => "/corrections/upload"
  mount ZipUploader.upload_endpoint(:submission_cache) => "/packages/upload"
  mount Thredded::Engine => '/forum'
  match '*path', to: 'main#error', via: :all

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
