Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'health' => 'rails/health#show', as: :rails_health_check

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

    concern :test_actions do
      member do
        post :start
        get 'question/:question_index', action: :question, as: :question
        post 'answer/:question_index', action: :answer, as: :answer
        get :results
      end
    end

    resources :theoretical_tests, only: [], controller: 'theoretical_tests', concerns: :test_actions
    resources :practical_tests,   only: [], controller: 'practical_tests', concerns: :test_actions

    # Admin routes
    namespace :admin do
      get 'dashboard', to: 'dashboard#index'

      resources :tests do
        member do
          patch :activate
          patch :deactivate
          post :duplicate
        end

        resources :test_attempts, only: %i[index show new create destroy] do
          member do
            post :reassign
            patch :extend_time
          end
        end
        resources :test_categories_tests, only: [] do
          post :update_positions, on: :collection
        end
        resources :practical_tasks, except: %i[index show] do
          collection do
            post :update_positions
          end
          resources :practical_task_results, only: %i[index show update]
        end
      end

      resources :test_categories do
        resources :questions, except: %i[show index] do
          resources :answers, except: %i[show index]
          post :update_positions, on: :collection
        end
      end

      resources :users, only: %i[index show]
    end
  end
end
