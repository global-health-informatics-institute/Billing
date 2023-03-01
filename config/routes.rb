Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'main#index'

  get "/main/index"

  get "login" => "sessions#login"
  get "location" => "sessions#location"
  post "location" => "sessions#add_location"
  post "login" => "sessions#create_session"
  get "/logout" => "sessions#destroy"

  get "/main/report_select"
  post "/main/income_summary"
  post "/main/cashier_summary"
  post "/main/daily_cash_summary"
  get "/main/daily_cash_summary"
  get "/main/print_daily_cash_summary"
  post "/main/census_report"
  get 'print_refund' => "deposits#print_refund"

  resources :patients do
    collection do
      get 'search'
      get 'ajax_search'
      get 'given_names'
      get 'family_names'
      get 'district'
      get 'traditional_authority'
      get 'village'
      get 'nationality'
      get 'landmark'
      get 'country'
      get 'patient_demographics(/:id)', action: :patient_demographics
      post 'process_result'
      post 'process_confirmation'
      post 'ajax_process_result'
      post 'confirm_demographics'
      post 'ajax_process_data'
      get 'patient_not_found(/:id)', action: :patient_not_found
      post 'patient_not_found(/:id)', action: :patient_not_found
      get 'print_national_id'
      get 'patient_by_id(/:id)', action: :patient_by_id
    end
    resources :order_entries
    resources :patient_accounts
    resources :deposits do
      collection do
        get 'reclaim_deposit'
      end
    end
  end

  resources :locations do
    collection do
      get 'search'
      get 'print_label'
    end
  end
  resources :user_properties
  resources :service_types
  resources :medical_scheme_providers do
    resources :medical_scheme
    collection do
      get 'suggestions'
    end
  end
  resources :sessions
  resources :users do
    collection do
      get 'roles'
    end
  end
  resources :order_entries do
    collection do
      post 'void'
    end
  end
  resources :services do
    collection do
      get 'suggestions'
    end
    resources :service_prices
  end
  resources :order_payments do
    collection do
      get 'print_receipt'
      post 'void'
    end
  end

end
