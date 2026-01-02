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

  resources :classrooms, except: [:destroy] do
    member do
      patch :toggle_trading
    end
    resources :grade_books, only: %i[show update] do
      member do
        post :finalize
      end
    end
    resources :students, except: %i[index show] do
      member do
        patch :reset_password
        patch :generate_password
      end
    end
    resources :classroom_enrollments, only: %i[create destroy] do
      member do
        patch :unenroll
      end
    end
  end

  namespace :admin do
    root "classrooms#index"
    resources :announcements
    resources :classrooms, except: [:destroy] do
      member do
        patch :toggle_archive
      end
    end
    resources :grades
    resources :portfolio_transactions, except: [:index]
    resources :schools
    resources :school_years
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
  end

  # Admin V2 - In-house admin implementation (dual-running with Administrate)
  namespace :admin_v2, path: "admin-new" do
    root "dashboard#index"

    # Component demo (development/testing only)
    resources :component_demo, only: %i[index show] do
      collection do
        get :form
      end
    end

    # Resource routes
    resources :announcements
    resources :classrooms do
      member do
        patch :toggle_archive
      end
    end
    resources :grades
    resources :schools
    resources :school_years
    resources :stocks
    resources :students
    resources :teachers
    resources :users
    resources :years
    resources :portfolio_transactions, except: [:index]
  end

  resources :orders do
    member do
      patch :cancel
    end
  end
  resources :portfolios, only: :show
  resources :stocks, only: %i[show index]
  resources :announcements, only: :show
end
