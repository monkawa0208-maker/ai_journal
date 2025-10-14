Rails.application.routes.draw do
  devise_for :users
  root "entries#index"
  resources :entries do
    post :generate_feedback, on: :member
    post :translate, on: :collection
  end
end
