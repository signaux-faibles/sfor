require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SignauxFaiblesV2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    # Localisation
    config.i18n.default_locale = :fr
    config.i18n.available_locales = %i[fr en]

    # Active Record encryption (OTP secrets).
    # Production runtime requires env vars from deploy (Ansible/Terraform).
    # Docker/CI asset precompile uses SECRET_KEY_BASE_DUMMY=1 and must boot
    # without those secrets; dummy keys are never used to encrypt user data.
    dummy_encryption_ok = !Rails.env.production? || ENV["SECRET_KEY_BASE_DUMMY"].present?
    encryption_key = lambda do |env_name, fallback|
      value = ENV[env_name].presence
      next value if value
      raise KeyError, "Missing environment variable: #{env_name}" unless dummy_encryption_ok

      fallback
    end
    config.active_record.encryption.primary_key =
      encryption_key.call("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", "abcdefghijklmnopqrstuvwxyz012345")
    config.active_record.encryption.deterministic_key =
      encryption_key.call("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", "abcdefghijklmnopqrstuvwxyz678901")
    config.active_record.encryption.key_derivation_salt =
      encryption_key.call("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", "zyxwvutsrqponmlkjihgfedcba987654")

    # Route 404s through the app so we can redirect with a flash.
    config.exceptions_app = routes
  end
end
