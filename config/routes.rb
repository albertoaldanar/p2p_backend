Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api, defautls: {format: :json} do
    namespace :v1 do
      get '/logout' => 'users#logout'
      post '/facebook' => 'users#facebook'
      get '/user_count' => 'users#all_users'
      post '/payments' => "users#add_card"
      get '/listing' => "rooms#your_listing"
      resources :rooms do
        member do
          get 'reservations' => "reservations#reservations_by_room" #localhost/rooms/4/reservations
        end
      end
      resources :reservations do
        member do
          post 'approved' => 'reservations#approved'
          post 'declined' => 'reservations#declined'
        end
      end
    end
  end
end
