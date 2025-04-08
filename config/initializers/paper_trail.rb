# frozen_string_literal: true

# Set the whodunnit value for PaperTrail
PaperTrail.request.whodunnit = lambda do
  if defined?(current_user) && current_user
    current_user.id
  else
    "system"
  end
end

# Enable PaperTrail based on environment variable
PaperTrail.enabled = ENV.fetch("PAPERTRAIL_ENABLED", "true") == "true" unless Rails.env.test?

# Set maximum number of versions to keep
PaperTrail.config.version_limit = ENV.fetch("PAPERTRAIL_MAX_VERSIONS", 1000).to_i
