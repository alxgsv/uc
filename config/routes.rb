Rails.application.routes.default_url_options[:host] = "#{ENV['HOST']}"

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace "api" do
    namespace "v1" do
      resources :projects do
        resources :files do
          member do
            post :complete
          end
          resources :actions, only: [] do
            collection do
              match :recognize, :moderate, :virus_scan, via: [:get, :post]
            end
          end
          resources :conversions, only: [:index] do
            collection do
              post :image, :video, :document, :remove_bg
            end
          end
        end
        resources :transfer_accelerations
        resources :groups do
          member do
            get :files
          end
        end
        resources :webhooks do
          collection do
            post :incoming
          end
        end
      end
    end
  end

  match "cdn/*path", to: "cdn#show", via: :all
end
