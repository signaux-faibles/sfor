Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :admin do
    resources :activity_sectors
    resources :campaigns
    resources :companies
    resources :departments
    resources :establishments
    resources :establishment_trackings
    resources :roles
    resources :users
    resources :entities
    resources :segments
    resources :tracking_labels

    root to: "activity_sectors#index"
  end

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
    resources :establishment_trackings, only: [:new, :create, :show, :destroy], path: 'accompagnements'
  end

  # Build a new 'accompagnement' from the Vue JS legacy app (using siret as query param)
  get 'establishment_trackings/new_by_siret', to: 'establishment_trackings#new_by_siret', as: 'new_establishment_tracking_by_siret'

  resources :companies, only: [:index, :show], path: 'entreprises'
  resources :campaigns, only: [:index, :show], path: 'campagnes'

  # Defines the root path route ("/")
  root "pages#home"
end