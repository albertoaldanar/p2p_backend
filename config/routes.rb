Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api, defautls: {format: :json} do
    namespace :v1 do
      get '/logout' => 'users#logout'
      post '/facebook' => 'users#facebook'
      get '/user_count' => 'users#all_users'
      post '/payments' => "users#add_card"
      resources :rooms
      resourses :reservations
    end
  end
end
