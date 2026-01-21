Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  get "up" => "rails/health#show", as: :rails_health_check

  resources :suppliers do
    resources :transfers, only: [ :new, :create ], module: :suppliers
  end
  resources :customers do
    get "groups/:name", on: :collection, action: :group, as: :group
    patch :opening_balance, on: :member, action: :update_opening_balance
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
  resources :loans do
    resources :loan_payments, only: [ :create, :destroy ]
  end

  resources :closings do
    member do
      get "customer_groups/:group_name/pdf", to: "closings#customer_group_pdf", as: :customer_group_pdf
    end
    resources :customer_closings do
      collection do
        get :group # /closings/:closing_id/customer_closings/group?name=ARQUI
      end
      member do
        get :pdf
        get :weekly_pdf
      end
    end
    resources :supplier_closings do
      member do
        get :pdf
        get :weekly_pdf
      end
    end
  end

  resource :dashboard, only: [ :show ], controller: :dashboards

  resource :kickoff, only: [ :show, :create ]
  get "kickoff/template/:type", to: "kickoffs#template", as: :kickoff_template

  root "dashboards#show"
end
