Rails.application.routes.draw do
  devise_for :users
  get 'campaigns/index'
  get 'campaigns/show'
  get 'pages/home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :establishments, only: [:index, :show], path: 'entreprises' do
    post 'follow', on: :member
    delete 'unfollow', on: :member
  end
  get 'my_establishments', to: 'establishments#my_establishments'

  resources :campaigns, only: [:index, :show], path: 'campagnes'
  resources :establishment_followers, only: [:create, :destroy], path: 'suivis-entreprises'

  # Defines the root path route ("/")
  root "pages#home"
end