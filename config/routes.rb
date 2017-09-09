Rails.application.routes.draw do

  get 'lectures/show'

  get 'lectures/index'

  devise_for :users
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
