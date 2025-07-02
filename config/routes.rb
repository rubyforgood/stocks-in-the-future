# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "classrooms#index"

  devise_for :users

  resources :classrooms do
    resources :students, except: [:index] do
      member do
        patch :reset_password
        patch :generate_password
      end
    end
  end

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

  resources :orders
  resources :stocks, only: %i[show index]
  resources :students, only: :show

  resources :users, only: [] do
    resource :portfolio, only: :show
  end
end
