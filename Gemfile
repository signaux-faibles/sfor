source "https://rubygems.org"

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2.1"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails", "~> 3.5.2"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.5.9"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", "~> 6.4.2"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails", "~> 2.1.0"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails", "~> 2.0.11"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails", "~> 1.3.4"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder", "~> 2.13.0"

# Use Redis adapter to run Action Cable in production
gem "redis", "~> 5.0.8"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", "~> 1.2024.2", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", "~> 1.18.4", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Import wekan data
gem "mongo", "~> 2.21.0"

# Decode keycloak tokens
gem "jwt", "~> 2.9.3"

# Allow requests from legacy vue app
gem "rack-cors", "~> 2.0.2"

# Search the data
gem "ransack", "~> 4.2.1"

# Basic admin
gem "administrate", "1.0.0.beta3"

# Authorizations
gem "pundit", "~> 2.4"

# Pagination
gem "kaminari", "~> 1.2", ">= 1.2.2"

# Import users from the habilitations file
gem "rubyXL", "~> 3.4", ">= 3.4.27"

# State machine for establishment trackings
gem "aasm", "~> 5.5"

# Links in summaries and comments made clickable
gem "rails_autolink", "~> 1.1", ">= 1.1.8"

# Handle soft delete
gem "discard", "~> 1.2"

# Track changes to models
gem "paper_trail", "~> 16.0"

# Impersonate users
gem "pretender", "~> 0.5.0"

# Generate excel files for establishment trackings
gem "caxlsx", "~> 4.1"

# Send issues to Sentry
gem "sentry-rails", "~> 5.22"
gem "sentry-ruby", "~> 5.22"

# Interpret the markdown used in the summaries
gem "redcarpet", "~> 3.6.0"

# Authentication
gem "devise", "~> 4.9", ">= 4.9.4"

# View component
gem "view_component"

# Add health check endpoint
gem "prometheus_exporter", "~> 2.2.0"

# Analytics
gem "ahoy_matey", "~> 5.4"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"

  # Generate fake data for development and testing
  gem "faker", "~> 3.5", ">= 3.5.1"

  # Code quality and style
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false

  # Security scanning
  gem "brakeman"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem "spring"

  # Generate erd diagrams
  gem "bullet"
  gem "rails-erd"

  # Model annotations
  gem "annotate"

  # Performance profiling
  gem "memory_profiler"
  gem "stackprof"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
end
