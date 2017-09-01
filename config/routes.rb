Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'tag/:id', :to => 'tag#show'
      get 'keks_question/:id', :to => 'medium#keks_question'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
