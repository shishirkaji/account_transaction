Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "transaction_files", to: "transaction_files#create"
  get "accounts", to: "accounts#index"
  get "transactions", to: "transactions#index"
  get "transaction_files", to: "transaction_files#index"
end
