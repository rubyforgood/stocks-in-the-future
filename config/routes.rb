Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  get "/teacher/home", to: "teacher#index"
end
