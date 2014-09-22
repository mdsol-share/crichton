require 'mauth/rack'
Crichton.initialize_registry((Rails.root + 'api_descriptors/medidation.yml').to_s)
middleware = Rails.application.config.middleware

if Rails.env.test? || Rails.env.development?
  middleware.insert_after MAuth::Rack::RequestAuthenticationFaker, Crichton::Middleware::AlpsProfileResponse, {'expiry' => 20}
  middleware.insert_after MAuth::Rack::RequestAuthenticationFaker, Crichton::Middleware::ServiceResourcesCatalog, {'expiry' => 20}
else
  middleware.insert_after MAuth::Rack::RequestAuthenticatorNoAppStatus, Crichton::Middleware::AlpsProfileResponse, {'expiry' => 20}
  middleware.insert_after MAuth::Rack::RequestAuthenticatorNoAppStatus, Crichton::Middleware::ServiceResourcesCatalog, {'expiry' => 20}
end
