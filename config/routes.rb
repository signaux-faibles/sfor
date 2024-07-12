Rails.application.routes.draw do
  get 'trackings/new'
  get 'trackings/create'
  get 'trackings/show'
  get 'trackings/destroy'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_scope :user do
    post 'authenticate', to: 'users/sessions#create'
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :establishments, only: [:index, :show], path: 'entreprises' do
    resources :trackings, only: [:new, :create, :show, :destroy]
  end

  resources :campaigns, only: [:index, :show], path: 'campagnes'

  namespace :admin do
    resources :campaigns, only: [:index, :show], path: 'campagnes'
    # Add here all the admin routes. This will be protected by Pundit and only accessible to users with the 'admin' role
  end

  # Defines the root path route ("/")
  root "pages#home"
end