Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV["VUE_APP_FRONTEND_URL"] || ''

    resource '*',
             headers: :any,
             methods: [:get, :post],
             credentials: true
  end
end