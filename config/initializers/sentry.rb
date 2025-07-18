Sentry.init do |config|
  config.enabled_environments = %w[development preprod production]
  config.debug = true
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.environment = ENV.fetch("SENTRY_ENV", nil)

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 0.02
end
