Rails.application.routes.draw do
  # mount sidekiq engine

  require "sidekiq/web"
  require "sidekiq/cron/web"

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  if Rails.env.test?
    namespace :cypress do
      resources :factories, only: :create
      post "factories/call_instance_method", to: "factories#call_instance_method"
      resources :database_cleaner, only: :create
      resources :user_creator, only: :create
      resources :i18n, only: :create
      post "timecop/travel", to: "timecop#travel"
      post "timecop/reset", to: "timecop#reset"
    end
  end

  # mount commontator engine

  mount Commontator::Engine => "/commontator"

  # search routes

  get "search/index"

  # administration routes

  get "/administration",
      to: "administration#index",
      as: "administration"

  get "/administration/exit",
      to: "administration#exit",
      as: "exit_administration"

  get "/administration/profile",
      to: "administration#profile",
      as: "elevated_profile"

  get "administration/search",
      to: "administration#search",
      as: "administration_search"

  get "/administration/classification",
      to: "administration#classification",
      as: "classification"

  # annotation routes
  get "annotations/update_annotations",
      to: "annotations#update_annotations",
      as: "update_annotations"

  get "annotations/num_nearby_posted_mistake_annotations",
      to: "annotations#num_nearby_posted_mistake_annotations",
      as: "num_nearby_posted_mistake_annotations"

  resources :annotations

  # announcements routes

  post "announcements/:id/propagate",
       to: "announcements#propagate",
       as: "propagate_announcement"

  post "announcements/:id/expel",
       to: "announcements#expel",
       as: "expel_announcement"

  resources :announcements, only: [:index, :new, :create]

  # answers routes
  get "answers/:id/cancel_edit",
      to: "answers#cancel_edit",
      as: "cancel_edit_answer"

  resources :answers, except: [:index, :show, :edit]

  # areas routes

  resources :areas, except: [:show]

  # assignments routes

  get "assignments/:id/cancel_edit",
      to: "assignments#cancel_edit",
      as: "cancel_edit_assignment"

  get "assignments/cancel_new",
      to: "assignments#cancel_new",
      as: "cancel_new_assignment"

  resources :assignments, only: [:new, :edit, :create, :update, :destroy]

  # chapters routes

  get "chapters/:id/list_sections",
      to: "chapters#list_sections",
      as: "list_sections"

  resources :chapters, except: [:index, :show]

  # courses routes

  post "courses/:id/take_random_quiz",
       to: "courses#take_random_quiz",
       as: "random_quiz"

  get "courses/:id/render_question_counter",
      to: "courses#render_question_counter",
      as: "render_question_counter"

  get "courses/search",
      to: "courses#search",
      as: "search_courses"

  resources :courses, except: [:index, :show, :new]

  # divisions routes

  resources :divisions, except: [:show]

  # feedback routes
  resources :feedbacks, only: [:create]

  # interactions routes

  get "interactions/export_interactions",
      as: "export_interactions"

  get "interactions/export_probes",
      as: "export_probes"

  resources :interactions, only: [:index]

  # items routes

  get "items/:id/display",
      to: "items#display",
      as: "display_item"

  resources :items, only: [:update, :create, :edit, :destroy]

  # lectures routes

  get "lectures/:id/material",
      to: "media#index",
      as: "lecture_material"

  # New semantic routes replace the old food routes
  get "lectures/:id/lesson_materials",
      to: "media#index",
      as: "lecture_lesson_materials",
      defaults: { project: "lesson_material" }

  get "lectures/:id/script",
      to: "media#index",
      as: "lecture_script",
      defaults: { project: "script" }

  get "lectures/:id/exercises",
      to: "media#index",
      as: "lecture_exercises",
      defaults: { project: "exercise" }

  get "lectures/:id/quizzes",
      to: "media#index",
      as: "lecture_quizzes",
      defaults: { project: "quiz" }

  get "lectures/:id/worked_examples",
      to: "media#index",
      as: "lecture_worked_examples",
      defaults: { project: "worked_example" }

  get "lectures/:id/repetitions",
      to: "media#index",
      as: "lecture_repetitions",
      defaults: { project: "repetition" }

  get "lectures/:id/miscellaneous",
      to: "media#index",
      as: "lecture_miscellaneous",
      defaults: { project: "miscellaneous" }

  get "lectures/:lecture_id/questionnaires",
      to: "vignettes/questionnaires#index",
      as: "lecture_questionnaires"

  get "lectures/:id/update_teacher",
      to: "lectures#update_teacher",
      as: "update_teacher"

  get "lectures/:id/update_editors",
      to: "lectures#update_editors",
      as: "update_editors"

  get "lectures/:id/add_forum",
      to: "lectures#add_forum",
      as: "add_forum"

  get "lectures/:id/lock_forum",
      to: "lectures#lock_forum",
      as: "lock_forum"

  get "lectures/:id/unlock_forum",
      to: "lectures#unlock_forum",
      as: "unlock_forum"

  get "lectures/:id/destroy_forum",
      to: "lectures#destroy_forum",
      as: "destroy_forum"

  get "lectures/:id/show_announcements",
      to: "lectures#show_announcements",
      as: "show_announcements"

  get "lectures/:id/organizational",
      to: "lectures#organizational",
      as: "organizational"

  get "lectures/:id/show_random_quizzes",
      to: "lectures#show_random_quizzes",
      as: "show_random_quizzes"

  get "lectures/:id/show_subscribers",
      to: "lectures#show_subscribers",
      as: "show_subscribers"

  get "lectures/:id/show_structures",
      to: "lectures#show_structures",
      as: "show_structures"

  get "lectures/:id/edit_structures",
      to: "lectures#edit_structures",
      as: "edit_structures"

  get "lectures/:id/search_examples",
      to: "lectures#search_examples",
      as: "search_examples"

  get "lectures/search",
      to: "lectures#search",
      as: "lecture_search"

  get "lectures/:id/display_course",
      to: "lectures#display_course",
      as: "display_course"

  post "lectures/:id/publish",
       to: "lectures#publish",
       as: "publish_lecture"

  post "lectures/:id/import_media",
       to: "lectures#import_media",
       as: "lecture_import_media"

  delete "lectures/:id/remove_imported_medium",
         to: "lectures#remove_imported_medium",
         as: "lecture_remove_imported_medium"

  get "lectures/:id/close_comments",
      to: "lectures#close_comments",
      as: "lecture_close_comments"

  get "lectures/:id/open_comments",
      to: "lectures#open_comments",
      as: "lecture_open_comments"

  get "lectures/:id/submissions",
      to: "submissions#index",
      as: "lecture_submissions"

  get "lectures/:id/tutorials",
      to: "tutorials#index",
      as: "lecture_tutorials"

  get "lectures/:id/tutorial_overview",
      to: "tutorials#overview",
      as: "lecture_tutorial_overview"

  get "lectures/:id/subscribe",
      to: "lectures#subscribe_page",
      as: "subscribe_lecture_page"

  post "lectures/:id/import_toc",
       to: "lectures#import_toc",
       as: "import_lecture_toc"

  resources :lectures, except: [:index]

  # lessons routes

  resources :lessons, except: [:index]

  # media routes

  get "media/search",
      to: "media#search",
      as: "media_search"

  get "media/:id/inspect",
      to: "media#inspect",
      as: "inspect_medium"

  get "media/:id/feedback",
      to: "media#feedback",
      as: "feedback_medium"

  get "media/:id/enrich",
      to: "media#enrich",
      as: "enrich_medium"

  get "media/:id/play",
      to: "media#play",
      as: "play_medium"

  get "media/:id/display",
      to: "media#display",
      as: "display_medium"

  get "media/:id/geogebra",
      to: "media#geogebra",
      as: "geogebra_medium"

  get "media/:id/add_item",
      to: "media#add_item",
      as: "add_item"

  get "media/:id/add_reference",
      to: "media#add_reference",
      as: "add_reference"

  get "media/:id/import_script_items",
      to: "media#import_script_items",
      as: "import_script_items"

  patch "media/:id/remove_screenshot",
        to: "media#remove_screenshot",
        as: "remove_screenshot"

  post "media/:id/add_screenshot",
       to: "media#add_screenshot",
       as: "add_screenshot"

  post "media/:id/publish",
       to: "media#publish",
       as: "publish_medium"

  post "media/:id/import_manuscript",
       to: "media#import_manuscript",
       as: "import_manuscript"

  get "media/fill_teachable_select",
      to: "media#fill_teachable_select",
      as: "fill_teachable_select"

  get "media/fill_media_select",
      to: "media#fill_media_select",
      as: "fill_media_select"

  post "media/update_tags",
       to: "media#update_tags",
       as: "update_tags"

  post "media/:id/register_download",
       to: "media#register_download",
       as: "register_download"

  get "media/:id/statistics",
      to: "media#statistics",
      as: "statistics"

  get "media/:id/show_comments",
      to: "media#show_comments",
      as: "show_media_comments"

  delete "media/:id/cancel_publication",
         to: "media#cancel_publication",
         as: "cancel_publication"

  get "media/:id/fill_medium_preview",
      to: "media#fill_medium_preview",
      as: "fill_medium_preview"

  get "media/:id/render_medium_actions",
      to: "media#render_medium_actions",
      as: "render_medium_actions"

  get "media/:id/render_import_media",
      to: "media#render_import_media",
      as: "render_import_media"

  get "media/:id/render_import_vertex",
      to: "media#render_import_vertex",
      as: "render_import_vertex"

  get "media/:id/render_medium_tags",
      to: "media#render_medium_tags",
      as: "render_medium_tags"

  get "media/cancel_import_media",
      as: "cancel_import_media"

  get "media/cancel_import_vertex",
      as: "cancel_import_vertex"

  get "media/:id/fill_quizzable_area",
      to: "media#fill_quizzable_area",
      as: "fill_quizzable_area"

  get "media/:id/fill_quizzable_preview",
      to: "media#fill_quizzable_preview",
      as: "fill_quizzable_preview"

  get "media/:id/fill_reassign_modal",
      to: "media#fill_reassign_modal",
      as: "fill_reassign_modal"

  get "media/:id/check_annotation_visibility",
      to: "media#check_annotation_visibility",
      as: "check_annotation_visibility"

  resources :media

  # notifications controller

  post "notifications/destroy_all",
       to: "notifications#destroy_all",
       as: "destroy_all_notifications"

  post "notifications/destroy_lecture_notifications",
       to: "notifications#destroy_lecture_notifications",
       as: "destroy_lecture_notifications"

  post "notifications/destroy_news_notifications",
       to: "notifications#destroy_news_notifications",
       as: "destroy_news_notifications"

  resources :notifications, only: [:index, :destroy]

  # profile routes

  get "profile/edit",
      as: "edit_profile"

  post "profile/update"

  get "profile/check_for_consent",
      as: "consent_profile"

  patch "profile/add_consent",
        as: "add_consent"

  put "profile/add_consent"

  post "profile/toggle_thread_subscription",
       as: "toggle_thread_subscription"

  patch "profile/subscribe_lecture",
        as: "subscribe_lecture"

  patch "profile/unsubscribe_lecture",
        as: "unsubscribe_lecture"

  get "profile/show_accordion",
      as: "show_accordion"

  patch "profile/star_lecture",
        as: "star_lecture"

  patch "profile/unstar_lecture",
        as: "unstar_lecture"

  get "profile/request_data",
      as: "request_data"

  # programs routes

  resources :programs, except: [:show]

  # questions routes

  patch "questions/:id/reassign",
        to: "questions#reassign",
        as: "reassign_question"

  patch "question/:id/set_solution_type",
        to: "questions#set_solution_type",
        as: "set_solution_type"

  get "questions/:id/cancel_question_basics",
      to: "questions#cancel_question_basics",
      as: "cancel_question_basics"

  get "questions/:id/cancel_solution_edit",
      to: "questions#cancel_solution_edit",
      as: "cancel_solution_edit"

  get "questions/:id/render_question_parameters",
      to: "questions#render_question_parameters",
      as: "render_question_parameters"

  resources :questions, only: [:edit, :update]

  # quizzes routes

  post "quiz_certificates/:id/claim",
       to: "quiz_certificates#claim",
       as: "claim_quiz_certificate"

  post "quiz_certificates/validate",
       to: "quiz_certificates#validate",
       as: "validate_certificate"

  get "quizzes/:id/take",
      to: "quizzes#take",
      as: "take_quiz"

  patch "quizzes/:id/take",
        to: "quizzes#proceed"

  put "quizzes/:id/take",
      to: "quizzes#proceed"

  patch "quizzes/:id/linearize",
        to: "quizzes#linearize",
        as: "linearize_quiz"
  post "quizzes/:id/set_root",
       to: "quizzes#set_root",
       as: "set_quiz_root"

  post "quizzes/:id/set_level",
       to: "quizzes#set_level",
       as: "set_quiz_level"

  post "quizzes/:id/update_default_target",
       to: "quizzes#update_default_target",
       as: "update_default_target"

  delete "quizzes/:id/delete_edge",
         to: "quizzes#delete_edge",
         as: "delete_edge"

  get "quizzes/update_branching",
      to: "quizzes#update_branching",
      as: "update_branching"

  get "quizzes/:id/edit_vertex_targets",
      to: "quizzes#edit_vertex_targets",
      as: "edit_vertex_targets"

  get "quizzes/:id/render_vertex_quizzable",
      to: "quizzes#render_vertex_quizzable",
      as: "render_vertex_quizzable"

  resources :quizzes, except: [:show, :index, :create] do
    resources :vertices, except: [:index, :show, :edit]
  end

  # vignettes routes
  get "questionnaires/:id/take",
      to: "vignettes/questionnaires#take",
      as: "take_questionnaire"
  get "questionnaires/:id/preview",
      to: "vignettes/questionnaires#preview",
      as: "preview_questionnaire"
  post "lectures/:id/questionnaires/set_codename",
       to: "vignettes/codenames#set_codename",
       as: "set_lecture_codename"
  post "lectures/:id/questionnaires/set_completion_message",
       to: "vignettes/completion_message#set_completion_message",
       as: "set_lecture_completion_message"
  delete "lectures/:id/questionnaires/destroy_completion_message",
         to: "vignettes/completion_message#destroy",
         as: "destroy_lecture_completion_message"

  scope module: "vignettes", path: "" do
    resources :questionnaires, only: [:create, :edit, :update, :destroy] do
      member do
        get :export_statistics
        post :submit_answer
        post :duplicate
        patch :publish
        patch :update_slide_position
      end
      resources :info_slides, only: [:new, :create, :edit, :update, :destroy]
      resources :slides, only: [:new, :create, :edit, :update, :destroy] do
        resources :answers, only: [:new, :create]
      end
    end
  end

  # readers routes

  patch "readers/update",
        to: "readers#update",
        as: "update_reader"

  patch "readers/update_all",
        to: "readers#update_all",
        as: "update_all_readers"

  # referrals routes

  get "referrals/list_items",
      to: "referrals#list_items",
      as: "list_items"

  resources :referrals, only: [:update, :create, :edit, :destroy]

  # remarks routes

  patch "remarks/:id/reassign",
        to: "remarks#reassign",
        as: "reassign_remark"

  get "remarks/:id/cancel_remark_basics",
      to: "remarks#cancel_remark_basics",
      as: "cancel_remark_basics"

  resources :remarks, only: [:edit, :update]

  # subjects routes

  resources :subjects, except: [:show]

  # submissions routes

  post "submissions/join",
       to: "submissions#join",
       as: "join_submission"

  get "submissions/enter_code",
      to: "submissions#enter_code",
      as: "enter_submission_code"

  get "submissions/redeem_code",
      to: "submissions#redeem_code",
      as: "redeem_submission_code"

  delete "submissions/:id/leave",
         to: "submissions#leave",
         as: "leave_submission"

  get "submissions/:id/cancel_edit",
      to: "submissions#cancel_edit",
      as: "cancel_edit_submission"

  get "submissions/cancel_new",
      to: "submissions#cancel_new",
      as: "cancel_new_submission"

  get "submissions/:id/show_manuscript",
      to: "submissions#show_manuscript",
      as: "show_submission_manuscript"

  patch "submissions/:id/refresh_token",
        to: "submissions#refresh_token",
        as: "refresh_submission_token"

  get "submissions/:id/enter_invitees",
      to: "submissions#enter_invitees",
      as: "enter_submission_invitees"

  post "submissions/:id/invite",
       to: "submissions#invite",
       as: "invite_to_submission"

  post "submissions/:id/add_correction",
       to: "submissions#add_correction",
       as: "add_correction"

  get "submissions/:id/show_correction",
      to: "submissions#show_correction",
      as: "show_correction"

  get "submissions/:id/select_tutorial",
      to: "submissions#select_tutorial",
      as: "select_tutorial"

  patch "submissions/:id/move",
        to: "submissions#move",
        as: "move_submission"

  get "submissions/:id/cancel_action",
      to: "submissions#cancel_action",
      as: "cancel_submission_action"

  delete "submissions/:id/delete_correction",
         to: "submissions#delete_correction",
         as: "delete_correction"

  patch "submissions/:id/accept",
        to: "submissions#accept",
        as: "accept_submission"

  patch "submissions/:id/reject",
        to: "submissions#reject",
        as: "reject_submission"

  get "submissions/:id/edit_correction",
      to: "submissions#edit_correction",
      as: "edit_correction"

  get "submissions/:id/cancel_edit_correction",
      to: "submissions#cancel_edit_correction",
      as: "cancel_edit_correction"

  resources :submissions, except: [:index, :show]

  # tags routes

  get "tags/modal",
      to: "tags#modal",
      as: "tag_modal"

  get "tags/:id/display_cyto",
      to: "tags#display_cyto",
      as: "display_cyto_tag"

  patch "tags/:id/identify",
        to: "tags#identify",
        as: "identify_tags"

  put "tags/:id/identify",
      to: "tags#identify"

  get "tags/fill_tag_select",
      to: "tags#fill_tag_select",
      as: "fill_tag_select"

  get "events/fill_course_tags",
      to: "tags#fill_course_tags",
      as: "fill_course_tags"

  get "tags/search",
      to: "tags#search",
      as: "tags_search"

  get "tags/:id/take_random_quiz",
      to: "tags#take_random_quiz",
      as: "tag_random_quiz"

  post "tags/postprocess",
       to: "tags#postprocess",
       as: "postprocess_tags"

  get "tags/render_tag_title",
      as: "render_tag_title"

  resources :tags, except: :index

  # talks routes

  get "talks/:id/assemble",
      to: "talks#assemble",
      as: "assemble_talk"

  post "talks/:id/modify",
       to: "talks#modify",
       as: "modify_talk"

  resources :talks, except: [:index]

  # tutorials routes

  get "tutorials/:id/cancel_edit",
      to: "tutorials#cancel_edit",
      as: "cancel_edit_tutorial"

  get "tutorials/cancel_new",
      to: "tutorials#cancel_new",
      as: "cancel_new_tutorial"

  get "tutorials/:id/assignments/:ass_id/bulk_download_submissions",
      to: "tutorials#bulk_download_submissions",
      as: "bulk_download_submissions"

  get "tutorials/:id/assignments/:ass_id/bulk_download_corrections",
      to: "tutorials#bulk_download_corrections",
      as: "bulk_download_corrections"

  patch "tutorials/:id/assignments/:ass_id/bulk_upload",
        to: "tutorials#bulk_upload",
        as: "bulk_upload_corrections"

  get "tutorials/validate_certificate",
      to: "tutorials#validate_certificate",
      as: "validate_certificate_as_tutor"

  get "tutorials/:id/assignments/:ass_id/export_teams",
      to: "tutorials#export_teams",
      as: "export_teams_to_csv"

  resources :tutorials, only: [:new, :edit, :create, :update, :destroy]

  # sections routes

  get "sections/:id/display",
      to: "sections#display",
      as: "display_section"

  resources :sections, except: [:index]

  # terms routes

  get "terms/cancel_term_edit",
      to: "terms#cancel",
      as: "cancel_term_edit"

  post "terms/set_active_term",
       to: "terms#set_active",
       as: "set_active_term"

  resources :terms, except: [:show]

  # devise routes for users

  devise_for :users, controllers: { confirmations: "confirmations",
                                    registrations: "registrations",
                                    sessions: "sessions" }
  # users routes

  get "users/elevate",
      to: "users#elevate",
      as: "elevate_user"

  get "users/teacher/:teacher_id",
      to: "users#teacher",
      as: "teacher"

  get "users/list_generic_users",
      to: "users#list_generic_users",
      as: "list_generic_users"

  get "users/fill_user_select",
      to: "users#fill_user_select",
      as: "fill_user_select"

  get "users/delete_account",
      to: "users#delete_account",
      as: "delete_account"

  resources :users, only: [:index, :edit, :update, :destroy]

  post "vouchers/verify",
       to: "vouchers#verify",
       as: "verify_voucher"

  post "vouchers/redeem",
       to: "vouchers#redeem",
       as: "redeem_voucher"

  post "vouchers/:id/invalidate",
       to: "vouchers#invalidate",
       as: "invalidate_voucher"

  get "vouchers/cancel",
      to: "vouchers#cancel",
      as: "cancel_voucher"

  resources :vouchers, only: [:create]

  # watchlists routes

  get "watchlists/add_medium/:medium_id",
      to: "watchlists#add_medium",
      as: "add_medium_to_watchlist"

  get "watchlists/add",
      to: "watchlists#add",
      as: "add_watchlist"

  get "watchlists/rearrange",
      to: "watchlists#update_order",
      as: "rearrange_watchlist"

  get "watchlists/change_visiblity",
      to: "watchlists#change_visibility",
      as: "change_visibility"

  resources :watchlists

  resources :watchlist_entries

  # erdbeere routes

  get "examples/:id",
      to: "erdbeere#show_example",
      as: "erdbeere_example"

  post "examples/find",
       to: "erdbeere#find_example"

  get "properties/:id",
      to: "erdbeere#show_property",
      as: "erdbeere_property"

  get "structures/:id",
      to: "erdbeere#show_structure",
      as: "erdbeere_structure"

  get "find_erdbeere_tags",
      to: "erdbeere#find_tags",
      as: "find_erdbeere_tags"

  post "update_erdbeere_tags",
       to: "erdbeere#update_tags",
       as: "update_erdbeere_tags"

  get "edit_erdbeere_tags",
      to: "erdbeere#edit_tags",
      as: "edit_erdbeere_tags"

  get "cancel_edit_erdbeere_tags",
      to: "erdbeere#cancel_edit_tags",
      as: "cancel_edit_erdbeere_tags"

  get "display_erdbeere_info",
      to: "erdbeere#display_info",
      as: "display_erdbeere_info"

  get "fill_realizations_select",
      to: "erdbeere#fill_realizations_select",
      as: "fill_realizations_select"

  # main routes

  # Ruby set root based on whether user is authenticated or not
  # https://stackoverflow.com/questions/37261620/change-root-depending-on-whether-a-user-is-logged-in-or-not-without-devise-on-ru
  # https://github.com/heartcombo/devise/blob/3926e6d9eb139cc839faec8ea6c8f8cefa2d95f6/lib/devise/rails/routes.rb#L296-L334
  # https://stackoverflow.com/a/27507722/
  devise_scope :user do
    authenticated :user do
      root to: "main#start"
    end

    unauthenticated do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end

  # Allow /login besides /users/sign_in
  devise_scope :user do
    get "/login" => "devise/sessions#new"
  end

  get "error",
      to: "main#error"

  get "main/news",
      to: "main#news",
      as: "news"

  get "main/comments",
      to: "main#comments",
      as: "comments"

  get "main/start",
      to: "main#start",
      as: "start"

  # uploader routes

  mount ScreenshotUploader.upload_endpoint(:cache) => "/screenshots/upload"
  mount ProfileimageUploader.upload_endpoint(:cache) => "/profile_image/upload"
  mount VideoUploader.upload_endpoint(:cache) => "/videos/upload"
  mount PdfUploader.upload_endpoint(:cache) => "/pdfs/upload"
  mount GeogebraUploader.upload_endpoint(:cache) => "/ggbs/upload"
  mount SubmissionUploader.upload_endpoint(:submission_cache) => "/submissions/upload"
  mount CorrectionUploader.upload_endpoint(:submission_cache) => "/corrections/upload"
  mount ZipUploader.upload_endpoint(:submission_cache) => "/packages/upload"

  # thredded routes

  mount Thredded::Engine => "/forum"

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # redirect bs requests to error page (except active storage routes)
  match "*path", to: "main#error", via: :all, constraints: lambda { |req|
    # https://github.com/rails/rails/issues/33423#issuecomment-407264058
    !req.path.starts_with?("/rails/active_storage")
  }

  match "/", to: "main#error", via: [:post, :put, :patch, :delete]

  # For details on the DSL available within this file,
  # see http://guides.rubyonrails.org/routing.html
end
