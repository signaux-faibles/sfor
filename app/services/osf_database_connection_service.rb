# app/services/osf_database_connection_service.rb
# Service to manage connection to the OSF database where the Go app writes data

class OsfDatabaseConnectionService
  include Singleton

  attr_reader :connection

  def initialize
    @connection = nil
    @logger = Rails.logger
  end

  def establish_connection
    return @connection if @connection&.active?

    # Create a new connection without affecting Rails' default connection
    @connection = PG.connect(
      host: ENV.fetch("OSF_DATABASE_HOST"),
      port: ENV.fetch("OSF_DATABASE_PORT", 5432),
      dbname: ENV.fetch("OSF_DATABASE_NAME"),
      user: ENV.fetch("OSF_DATABASE_USERNAME"),
      password: ENV.fetch("OSF_DATABASE_PASSWORD")
    )

    @logger.info "Connected to OSF database: #{ENV.fetch('OSF_DATABASE_HOST',
                                                         nil)}/#{ENV.fetch('OSF_DATABASE_NAME', nil)}"
    @connection
  rescue StandardError => e
    @logger.fatal "Failed to connect to OSF database: #{e.message}"
    raise
  end

  def execute_query(sql)
    establish_connection unless @connection
    @connection.exec(sql)
  end

  def disconnect
    @connection&.close
    @connection = nil
    @logger.info "Disconnected from OSF database"
  end

  def self.with_connection
    service = instance
    service.establish_connection
    yield service
  ensure
    service&.disconnect
  end
end
