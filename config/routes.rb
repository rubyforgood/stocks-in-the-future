Rails.application.routes.draw do
  devise_for :users

  root to: "devise/sessions#new"
end
