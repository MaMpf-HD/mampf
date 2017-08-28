Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'tag/:id', :to => 'tag#show'
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
