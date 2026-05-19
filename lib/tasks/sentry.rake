namespace :sentry do
  desc "Send a test message to Sentry (requires SENTRY_DSN)"
  task test: :environment do
    abort "SENTRY_DSN is not set. Add it to .env and restart the web container." if ENV["SENTRY_DSN"].blank?

    sentry_environment = ENV.fetch("SENTRY_ENV", Rails.env)

    event_id = Sentry.capture_message(
      "Sentry Rails test from #{Rails.env} at #{Time.current.iso8601}"
    )
    Sentry.close

    if event_id
      puts "OK — sent event #{event_id} (environment: #{sentry_environment})"
      puts "Check Sentry → Issues, filter environment: #{sentry_environment}"
    else
      abort "Sentry did not return an event id (is the SDK enabled for #{Rails.env}?)"
    end
  end
end
