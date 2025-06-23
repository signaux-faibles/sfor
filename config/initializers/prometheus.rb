require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

# Enable gzip compression for the metrics endpoint
Rails.application.config.middleware.use Rack::Deflater

# Add Prometheus collector middleware to trace HTTP requests
Rails.application.config.middleware.use Prometheus::Middleware::Collector

# Add Prometheus exporter middleware to expose metrics endpoint
Rails.application.config.middleware.use Prometheus::Middleware::Exporter
