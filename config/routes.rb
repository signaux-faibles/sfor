Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions'}

  devise_scope :user do
    # Handle OmniAuth failures
    get '/users/auth/failure', to: 'users/omniauth_callbacks#failure'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :establishments, only: [:index, :show], path: 'entreprises' do
    post 'follow', on: :member
    delete 'unfollow', on: :member
  end
  get 'my_establishments', to: 'establishments#my_establishments'

  resources :campaigns, only: [:index, :show], path: 'campagnes'
  resources :establishment_followers, only: [:create, :destroy], path: 'suivis-entreprises'

  namespace :admin do
    resources :campaigns, only: [:index, :show], path: 'campagnes'
    # Add here all the admin routes. This will be protected by Pundit and only accessible to users with the 'admin' role
  end

  # Defines the root path route ("/")
  root "pages#home"
end