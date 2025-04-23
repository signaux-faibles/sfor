Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  get "unauthorized", to: "pages#unauthorized"
  get "statistiques", to: "statistics#index"

  namespace :admin do
    resources :users do
      get "/impersonate" => "users#impersonate"
      get "/discard" => "users#discard"
      get "/undiscard" => "users#undiscard"
    end
    resources :entities
    resources :networks
    resources :segments
    resources :departments
    resources :regions
    resources :geo_accesses
    resources :companies
    resources :establishments
    resources :establishment_trackings
    resources :tracking_labels
    resources :difficulties
    resources :user_actions
    resources :codefi_redirects
    resources :supporting_services

    root to: "users#index"
  end

  resources :users do
    collection do
      post :stop_impersonating
      post :set_time_zone
    end
  end

  devise_scope :user do
    post "authenticate", to: "users/sessions#create"
  end

  resources :establishments, only: [:show], path: "etablissements" do
    resources :establishment_trackings, only: %i[new create show destroy edit update], path: "accompagnements" do
      member do
        get :confirm
        patch :complete
        get :manage_contributors
        patch :update_contributors
        delete :remove_referent
        delete :remove_participant
      end
      resources :summaries, only: %i[create edit update] do
        get :cancel, on: :member
      end
      resources :comments, only: %i[create edit update destroy]
      resources :contacts, only: %i[new create edit update destroy] do
        member do
          get :archive
        end
      end
    end
  end

  resources :establishment_trackings, only: [:index], defaults: { format: :html }, path: "accompagnements"

  # Build a new 'accompagnement' from the Vue JS legacy app (using siret as query param)
  get "establishment_trackings/new_by_siret", to: "establishment_trackings#new_by_siret",
                                              as: "new_establishment_tracking_by_siret"

  root "establishment_trackings#index"
end
