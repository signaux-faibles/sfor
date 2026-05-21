source "https://rubygems.org"

ruby "3.2.2"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use dartsass-rails to compile sass
gem "dartsass-rails"

# Use postgresql as the database for Active Record
gem "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Decode keycloak tokens
gem "jwt"

# Allow requests from legacy vue app
gem "rack-cors"

# Search the data
gem "ransack"

# Authorizations
gem "pundit"

# Pagination
gem "kaminari"

# Import users from the habilitations file
gem "rubyXL"

# State machine for establishment trackings
gem "aasm"

# Links in summaries and comments made clickable
gem "rails_autolink"

# Handle soft delete
gem "discard"

# Track changes to models (17+ for Rails 8.1)
gem "paper_trail", "~> 17.0"

# Impersonate users
gem "pretender"

# Generate excel files for establishment trackings
gem "caxlsx"

# Send issues to Sentry
gem "stackprof"
gem "sentry-rails" # rubocop:disable Bundler/OrderedGems
gem "sentry-ruby"

# Interpret the markdown used in the summaries
gem "redcarpet"

# Authentication
gem "devise"

# View component (4.x for Rails 8)
gem "view_component", "~> 4.0"

# Add health check endpoint
gem "prometheus_exporter"

# Analytics
gem "ahoy_matey"

# Background job processing (uses PostgreSQL — no extra infrastructure needed)
gem "solid_queue"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]
  gem "dotenv-rails"

  # Generate fake data for development and testing
  gem "faker"

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

  # Preview emails in browser instead of sending them
  gem "letter_opener"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  gem "spring"

  # N+1 query detection (8.1+ for Active Record 8.1)
  gem "bullet", "~> 8.1"
  gem "rails-erd"

  # Model annotations (Rails 8–compatible fork of annotate)
  gem "annotaterb"

  # Performance profiling
  gem "memory_profiler"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
end
