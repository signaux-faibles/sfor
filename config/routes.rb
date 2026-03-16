Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }, skip: [:registrations]

  get "unauthorized", to: "pages#unauthorized"
  get "accueil", to: "pages#home", as: :home
  get "recherche", to: "pages#search", as: :search
  get "statistiques", to: "statistics#index"
  get "accessibilite", to: "pages#accessibilite", as: :accessibilite
  get "support", to: "pages#support", as: :support

  namespace :admin do
    resources :users do
      member do
        get :impersonate
        post :reset_password
      end
    end
    resources :imports
    resources :app_settings

    root to: "users#index"
  end

  resources :users do
    collection do
      post :stop_impersonating
      post :set_time_zone
      post :acknowledge_confidentiality
    end
  end

  get "entreprises", to: "pages#not_found_redirect"
  get "etablissements", to: "pages#not_found_redirect"
  get "etablissements/:siret/accompagnements", to: "pages#establishment_trackings_not_found",
                                               as: :establishment_trackings_not_found

  resources :establishments, only: [:show], path: "etablissements", param: :siret do
    member do
      get :insee_widget
      get :data_urssaf_widget
      get :data_effectif_ap_widget
      get :establishment_trackings_list_widget
    end
    resources :establishment_trackings, only: %i[new create show destroy edit update], path: "accompagnements" do
      member do
        get :confirm
        patch :complete
        post :duplicate
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
      get :detection_widget
      get :history_detection_widget
      get :waterfall_detection_widget
      match :feedback_detection_widget, via: %i[get post]
    end
  end

  resources :establishment_trackings, only: [:index], defaults: { format: :html }, path: "accompagnements"

  # Build a new 'accompagnement' from the Vue JS legacy app (using siret as query param)
  get "establishment_trackings/new_by_siret", to: "establishment_trackings#new_by_siret",
                                              as: "new_establishment_tracking_by_siret"

  resources :lists, path: "listes", only: %i[index show], defaults: { format: :html } do
    member do
      get :enrich_company
      get :alert_breakdown
      get :load_more
      get :company_count
    end
  end

  root "pages#home"

  match "*unmatched", to: "pages#not_found_redirect", via: :all
end
