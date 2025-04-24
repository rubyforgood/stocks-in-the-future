Rails.application.routes.draw do
  resources :orders
  namespace :admin do
    resources :schools
    resources :school_years
    resources :classrooms
    resources :stocks

    # resources :portfolios
    # resources :portfolio_stocks
    resources :portfolio_transactions, except: [:index]
    resources :students
    resources :teachers
    resources :users
    resources :years

    root to: "classrooms#index"
  end
  devise_for :users
  resources :classrooms
  resources :schools
  resources :students, only: [:show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Defines the root path route ("/")
  root "schools#index"

  get "portfolios/:user_id", to: "portfolios#portfolio", as: "student_portfolio"
end
