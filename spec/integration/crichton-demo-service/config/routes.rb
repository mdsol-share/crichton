CrichtonDemoService::Application.routes.draw do
  root to: 'drds#index'
  
  resources :drds do
    member do
      put 'activate'
      put 'deactivate'
    end
  end
  
end
