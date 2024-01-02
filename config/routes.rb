Rails.application.routes.draw do
  namespace :admin do
      resources :academic_years
      resources :cohorts
      resources :schools
      resources :school_periods
      resources :school_weeks
      resources :student_attendances
      resources :users
      resources :weeks

      root to: "academic_years#index"
    end
  devise_for :users, skip: :registrations

  root "home#index"
end
