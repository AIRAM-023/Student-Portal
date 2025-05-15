Rails.application.routes.draw do
  # Root path and homepage routes
  root "home#index"  # Set the home page route
  
  # Routes for static pages
  get 'about_us', to: 'home#about_us', as: 'about_us'
  get 'features', to: 'home#features', as: 'features'
  get 'contact_us', to: 'home#contact_us', as: 'contact_us'
  get 'privacy_policy', to: 'home#privacy_policy', as: 'privacy_policy'
  get 'home/dashboard', to: 'home#dashboard', as: 'home_dashboard'
  get 'ai_summary_test', to: 'home#ai_summary_test'


  post '/ask_ai', to: 'ai_chat#ask'
post '/ask_ai', to: 'ai#ask'

  
  # Routes for authentication (if you're using Devise)
  devise_for :users
  
  # Routes for AI summaries
  get 'ai/summary', to: 'ai#summary'
  post 'ai/summary', to: 'ai#summary'
  get 'chat', to: 'chat#chat'

  resources :documents, only: [:new, :create, :show] do
    member do
      get 'download_summary', defaults: { format: 'txt' }
    end
  end

  # Routes for document management
  # config/routes.rb
# config/routes.rb
resources :documents

resources :documents, only: [:index, :new, :create, :show]
# Only the actions you need
post 'documents/upload', to: 'documents#upload'  # If you have an upload action
get 'documents/:id/download_summary', to: 'documents#download_summary', as: 'download_summary'   # For downloading summaries

  # Route to handle health check for uptime monitoring
  get "up" => "rails/health#show", as: :rails_health_check

  # Define the authenticated root route
  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end
  
  # Define the unauthenticated root route
  unauthenticated do
    root to: "home#index", as: :unauthenticated_root
  end
  
  # Routes for notes (you can adjust as needed)
  resources :notes do
    member do
      post :summarize
    end
  end
end
