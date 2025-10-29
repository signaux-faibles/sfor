Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  get "unauthorized", to: "pages#unauthorized"
  get "accueil", to: "pages#home", as: :home
  get "recherche", to: "pages#search", as: :search
  get "statistiques", to: "statistics#index"

  # Routes pour les graphiques de test
  resources :charts, only: [:index] do
    collection do
      get :line_data
      get :bar_data
    end
  end

  namespace :admin do
    resources :users do
      member do
        get :impersonate
      end
    end

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

  resources :establishments, only: [:show], path: "etablissements", param: :siret do
    member do
      get :insee_widget
    end
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

  resources :companies, path: "entreprises", only: %i[show], param: :siren do
    member do
      get :insee_widget
      get :data_urssaf_widget
      get :data_effectif_ap_widget
      get :financial_widget
      get :establishments_widget
      get :establishment_trackings_list_widget
    end
  end

  resources :establishment_trackings, only: [:index], defaults: { format: :html }, path: "accompagnements"

  # Build a new 'accompagnement' from the Vue JS legacy app (using siret as query param)
  get "establishment_trackings/new_by_siret", to: "establishment_trackings#new_by_siret",
                                              as: "new_establishment_tracking_by_siret"

  root "establishment_trackings#index"
end
