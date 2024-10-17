Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  namespace :admin do
    resources :users do
      get '/impersonate' => "users#impersonate"
    end
    resources :establishments
    resources :establishment_trackings
    resources :activity_sectors
    resources :campaigns
    resources :companies
    resources :roles
    resources :entities
    resources :segments
    resources :departments
    resources :regions
    resources :geo_accesses
    resources :label_groups
    resources :tracking_labels

    root to: "activity_sectors#index"
  end

  resources :users do
    post :stop_impersonating, on: :collection
  end

  devise_scope :user do
    post 'authenticate', to: 'users/sessions#create'
  end

  resources :establishments, only: [:show], path: 'etablissements' do
    resources :establishment_trackings, only: [:new, :create, :show, :destroy, :edit, :update], path: 'accompagnements' do
      member do
        get :complete
        get :start_surveillance
        get :resume
      end
      resources :summaries, only: [:create, :edit, :update]
      resources :comments, only: [:create, :edit, :update, :destroy]
    end
  end

  resources :establishment_trackings, only: [:index], defaults: { format: :html }, path: 'accompagnements'

  # Build a new 'accompagnement' from the Vue JS legacy app (using siret as query param)
  get 'establishment_trackings/new_by_siret', to: 'establishment_trackings#new_by_siret', as: 'new_establishment_tracking_by_siret'

  root "establishment_trackings#index"
end