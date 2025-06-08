Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "classrooms#index"

  devise_for :users

  namespace :admin do
    root "classrooms#index"
    resources :classrooms
    resources :portfolio_transactions, except: [:index]
    resources :school_years, except: %i[new edit]
    resources :schools
    resources :stocks
    resources :students
    resources :teachers
    resources :users
    resources :years
  end

  resources :classrooms
  resources :orders
  resources :portfolios, only: :show
  resources :stocks, only: %i[show index]
  resources :students, only: :show
end
