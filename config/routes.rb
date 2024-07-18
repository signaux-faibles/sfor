Rails.application.routes.draw do
  namespace :admin do
      resources :activity_sectors
      resources :campaigns
      resources :companies
      resources :departments
      resources :establishments
      resources :establishment_trackings
      resources :roles
      resources :tracking_participants
      resources :users

      root to: "activity_sectors#index"
    end
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

  resources :establishments, only: [:index, :show], path: 'etablissements' do
    resources :trackings, only: [:new, :create, :show, :destroy]
  end


  resources :companies, only: [:index, :show], path: 'entreprises'
  resources :campaigns, only: [:index, :show], path: 'campagnes'

  # Defines the root path route ("/")
  root "pages#home"
end