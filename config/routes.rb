Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  resources :suppliers do
    resources :transfers, only: [ :new, :create ], module: :suppliers
  end
  resources :customers do
    get "groups/:name", on: :collection, action: :group, as: :group
    resources :transfers, only: [ :new, :create ], module: :customers
  end

  resources :sales do
    get :prefill, on: :collection
    resources :sales_users, only: [ :new, :create, :destroy ]
    resources :transfers,   only: [ :new, :create, :index ]
    collection do
      post :close_today # /sales/close_today
    end
    post :attach_file, on: :member
    delete :delete_attachment, on: :member
  end

  resources :sales_users, only: [ :index ]
  resources :transfers, only: [ :new, :create, :show, :edit, :update, :destroy, :index ]

  resources :closings do
    resources :customer_closings, only: [ :index, :show, :edit, :update ] do
    collection do
      get :group # /closings/:closing_id/customer_closings/group?name=ARQUI
      end
    end
    resources :supplier_closings, only: [ :index, :show, :new, :create, :edit, :update ]
  end

  resource :kickoff, only: [ :show, :create ]
  get "kickoff/template/:type", to: "kickoffs#template", as: :kickoff_template

  root "sales#index"
end
