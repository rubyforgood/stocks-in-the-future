# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"

  devise_for :users

  devise_scope :user do
    get "users/sign_up", to: redirect("/")
  end

  resources :users do
    resources :portfolios, only: :show
  end

  resources :classrooms do
    resources :grade_books, only: %i[show update] do
      member do
        post :finalize
      end
    end
    resources :students, except: [:index] do
      member do
        patch :reset_password
        patch :generate_password
      end
    end
  end

  namespace :admin do
    root "classrooms#index"
    resources :announcements
    resources :classrooms
    resources :portfolio_transactions, except: [:index]
    resources :school_years
    resources :schools
    resources :stocks
    resources :students do
      collection do
        post :import
        get :template
      end
      post "add_transaction"
      member do
        patch :restore
      end
    end
    resources :teachers
    resources :users
    resources :years
  end

  resources :orders do
    member do
      patch :cancel
    end
  end
  resources :portfolios, only: :show
  resources :stocks, only: %i[show index]
  resources :students, only: :show
  resources :announcements, only: :show
end
