Rails.application.routes.draw do
  resources :classrooms
  resources :schools
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # Routes for User Portfolio
  resources :users, only: [] do
    resource :portfolio, only: [:show], controller: 'portfolios'
  end
  get '/:user_id/portfolio', to: 'portfolios#show'
end
