Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Core journal functionality
  resources :journal_entries do
    collection do
      get 'for_date/:date', to: 'journal_entries#show_for_date', as: 'for_date'
    end
  end

  # Dashboard
  get "dashboard", to: "dashboard#index"
  get "dashboard/calendar", to: "dashboard#calendar"

  # Static pages
  get "about", to: "pages#about"
  get "privacy", to: "pages#privacy"

  # User profile
  resources :users, only: [:show, :edit, :update]

  # Defines the root path route ("/")
  # root "posts#index"
end
