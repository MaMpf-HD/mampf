Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'tags', :to => 'tags#index'
      get 'tags/:id', :to => 'tags#show'
      get 'keks_questions/:id', :to => 'media#keks_question'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
