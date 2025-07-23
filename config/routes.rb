Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Internationalization scope
  scope '(:locale)', locale: /#{I18n.available_locales.join('|')}/ do
    root 'home#index'

    devise_for :users, controllers: {
      sessions: 'users/sessions'
    }

    devise_scope :user do
      get 'login', to: 'users/sessions#new'
      get 'logout', to: 'users/sessions#destroy'
    end

    # Accreditation system routes
    resources :tests, only: [:index, :show] do
      member do
        post :start
        get :question, path: 'question/:question_index', as: :question
        post :answer, path: 'answer/:question_index', as: :answer
        get :finish, as: :finish
        get :results, as: :results
      end
    end

    # Admin routes
    namespace :admin do
      get 'dashboard', to: 'dashboard#index'

      resources :tests do
        member do
          patch :activate
          patch :deactivate
          post :duplicate
        end

        resources :test_attempts, only: [:index, :show]
      end

      resources :test_categories, except: [:show] do
        resources :questions, except: [:show] do
          post :duplicate, on: :member
          resources :answers, except: [:show]
        end
      end

      resources :users, only: [:index, :show]
      resources :test_attempts, only: [:index, :show]
    end
  end
end
