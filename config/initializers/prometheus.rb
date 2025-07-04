unless Rails.env.test?
  require "prometheus_exporter/middleware"

  # Config for PrometheusExporter to connect to the exporter service
  PrometheusExporter::Client.default = PrometheusExporter::Client.new(
    host: ENV.fetch("PROMETHEUS_EXPORTER_HOST", "localhost"),
    port: ENV.fetch("PROMETHEUS_EXPORTER_PORT", 9394)
  )

  Rails.application.middleware.unshift PrometheusExporter::Middleware
end