Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  resources :suppliers
  resources :customers

  resources :sales do
    get :prefill, on: :collection
    resources :sales_users, only: [ :new, :create, :destroy ]
    resources :transfers,   only: [ :new, :create, :index ]
     collection do
      post :close_today # /sales/close_today
    end
  end

  resources :transfers, only: [ :show, :edit, :update, :destroy, :index ]

  resources :closings do
    resources :customer_closings
    resources :supplier_closings
  end

  root "sales#index"
end
