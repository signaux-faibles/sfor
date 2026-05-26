Sentry.init do |config|
  config.enabled_environments = %w[development preprod production]
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.environment = ENV.fetch("SENTRY_ENV", Rails.env)

  config.debug = Rails.env.development?
  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0

  container_role = ENV["SENTRY_CONTAINER_ROLE"].presence
  if container_role
    tag_event = lambda do |event, _hint|
      event.tags["container_role"] = container_role
      event
    end

    config.before_send = tag_event
    config.before_send_transaction = tag_event
  end
end
