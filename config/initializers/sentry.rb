Sentry.init do |config|
  config.enabled_environments = %w[development preprod production]
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.environment = ENV.fetch("SENTRY_ENV", Rails.env)

  config.debug = Rails.env.development?
  config.traces_sample_rate = 1.0
end
