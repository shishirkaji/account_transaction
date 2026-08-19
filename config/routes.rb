Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "transaction_files", to: "transaction_files#create"
end
