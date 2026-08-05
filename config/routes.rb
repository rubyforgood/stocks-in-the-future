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

  # only: [] because there is no top-level UsersController. index / show / new / edit / create /
  # update / destroy were all routed and all raised "uninitialized constant UsersController";
  # nothing linked to any of them. The nested portfolio route is the only one this block was ever
  # for, and PortfoliosController serves it.
  resources :users, only: [] do
    resources :portfolios, only: :show
  end

  resources :classrooms, except: [:destroy] do
    member do
      patch :toggle_trading
    end
    resources :grade_books, only: %i[show update] do
      member do
        post :finalize
        post :populate
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

  # In-house admin (formerly admin_v2 at /admin-new, now at /admin)
  namespace :admin do
    root "dashboard#index"

    resources :component_demo, only: %i[index show] do
      collection do
        get :form
      end
    end

    resources :announcements
    resources :classrooms, except: [:destroy] do
      member do
        patch :toggle_archive
      end
    end
    resources :schools
    resources :school_years
    resources :stocks
    resources :students do
      collection do
        post :import
        get :template
      end
      member do
        patch :restore
        post :add_transaction
      end
    end
    resources :teachers do
      resource :deactivation, only: [:create], controller: "teachers/deactivations"
      resource :reactivation, only: [:create], controller: "teachers/reactivations"
    end
    resources :users
    # index was excluded, which left transactions reachable only if you already had an id:
    # every other CRUD action existed, the sidebar had no entry, and the dashboard listed
    # "Portfolio transactions" as dead grey text because there was nothing to link to.
    resources :portfolio_transactions
  end

  # No show or destroy: neither action exists on OrdersController, and orders/show.html.erb was
  # scaffolding that rendered `render @order` with @order never assigned - so GET /orders/:id
  # raised "'nil' is not an ActiveModel-compatible object" for every order, on a route nothing in
  # the app linked to. An order is read on orders#index; cancelling is the destructive path.
  resources :orders, except: %i[show destroy] do
    member do
      patch :cancel
    end
  end
  resources :portfolios, only: :show do
    member do
      # Dismisses the first-share message. A PATCH because it changes a record, and its own action
      # rather than a portfolio update so nothing else about a portfolio becomes writable here.
      patch :acknowledge_first_share
    end
  end
  resources :stocks, only: %i[show index]
  resources :announcements, only: :show
end
