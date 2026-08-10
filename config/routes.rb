# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  root "home#index"

  # Registrations, minus the account-edit half. /profile/edit is the account page: it sets a display
  # name, which Devise's registrations#edit cannot, and it does not demand the current password
  # before it will save one. Keeping both left two pages doing the same job, one of them worse.
  #
  # What is deliberately not routed any more:
  #
  #   PATCH/PUT /users (registrations#update) - nothing renders a form posting to it now that
  #     registrations/edit is gone, and leaving it routed would make a validation failure render a
  #     template that no longer exists.
  #   DELETE /users (registrations#destroy) - the "Delete account" button. It never worked: User
  #     raises "Hard delete attempted ... Use #discard instead", so the button returned a 500, and it
  #     had no test at all. Had it worked it would have been worse - portfolio and orders are
  #     `dependent: :destroy`, so a student could have deleted their own money history. Account
  #     removal here is an adult's action and already exists as admin Deactivate / Reactivate, which
  #     discards rather than destroys.
  #   /users/cancel (registrations#cancel) - part of the same self-service delete flow.
  #
  # A previous `devise_scope` block redirected users/sign_up to root, but it was declared *after*
  # devise_for, and the first matching route wins - so it never fired and sign-up rendered anyway.
  # Removed rather than moved: whether public sign-up should be open at all is a product question,
  # recorded in design-todo, and a dead route that reads as though it closed sign-up is worse than
  # no route.
  devise_for :users, skip: %i[registrations]

  devise_scope :user do
    get "users/sign_up", to: "devise/registrations#new", as: :new_user_registration
    post "users", to: "devise/registrations#create", as: :user_registration
    get "users/edit", to: redirect("/profile/edit"), as: :edit_user_registration
  end

  # only: [] because there is no top-level UsersController. index / show / new / edit / create /
  # update / destroy were all routed and all raised "uninitialized constant UsersController";
  # nothing linked to any of them. The nested portfolio route is the only one this block was ever
  # for, and PortfoliosController serves it.
  resources :users, only: [] do
    resources :portfolios, only: :show
  end

  # Your own account. design-todo recorded that there was no profile page: a top-level
  # UsersController was routed for seven actions and had never existed, and Devise's
  # registrations#edit demanded the current password before you could change anything - so a
  # student, who signs in with a username and may have no email, had no way to set a display name.
  #
  # Password lives on its own action because changing a display name should not require the
  # current password, and changing a password must. One form each, the way GitHub and Stripe
  # split them.
  resource :profile, only: %i[edit update] do
    patch :password
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

    # The component demo is a developer reference, not a product destination, and until now only its
    # *link* was guarded - the routes were declared unconditionally, so on production /admin/component_demo
    # was a live page for any admin, listing ten real users and their email addresses under a heading
    # saying "Component demo". `local?` is development and test, which excludes staging as well as
    # production, and it lets the suite render the page - the previous guard was `development?`, so no test
    # could see the page or its nav row, which is how the row kept a 44px height after NavHelper moved to 36.
    if Rails.env.local?
      resources :component_demo, only: %i[index show] do
        collection do
          get :form
          # A design preview: the save indicator's churn, and what the finalize card should be called.
          get :save_indicator
        end
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
    # `restore`, so a discarded user has a way back. admin/students#restore and the teachers'
    # reactivation cover the two subclasses; a user who is neither had no route at all - the discard is
    # reversible in the data and was irreversible only in the interface.
    resources :users do
      member do
        patch :restore
      end
    end
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
  resources :portfolios, only: :show

  # One endpoint for every dismissible banner. This was two member actions on portfolios - one per
  # banner - which is a route, a controller action and a column for each new thing a reader can close.
  # The key identifies what was dismissed and is checked against Dismissal::KEYS.
  resources :dismissals, only: :create
  resources :stocks, only: %i[show index]
  resources :announcements, only: :show
end
