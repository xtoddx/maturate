Rails.application.routes.draw do
  scope '/api' do
    scope '/:api_version' do
      resources :humans do
        collection do
          get :index2
        end
      end
    end
  end
  scope '/not-api' do
    resources :benefits_packages
  end
end
