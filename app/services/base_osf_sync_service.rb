# app/services/base_osf_sync_service.rb
# Base class for OSF data synchronization services

class BaseOsfSyncService
  attr_reader :logger, :stats

  def initialize
    @logger = setup_logger
    @stats = initialize_stats
    @logger.info "Starting #{self.class.name} at #{Time.current}"
  end

  def perform # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    OsfDatabaseConnectionService.with_connection do |db_service|
      @db_service = db_service
      sync_data
    end
    log_final_stats
    Rails.logger.debug completion_message
  rescue StandardError => e
    @logger.fatal "Fatal error during #{self.class.name}: #{e.message}"
    @logger.fatal e.backtrace.join("\n")
    Rails.logger.debug { "Fatal error during synchronization: #{e.message}" }
    raise
  ensure
    @log_file&.close
  end

  protected

  # Override these methods in subclasses
  def sync_data
    raise NotImplementedError, "Subclasses must implement sync_data"
  end

  def log_file_name
    raise NotImplementedError, "Subclasses must implement log_file_name"
  end

  def completion_message
    "#{self.class.name} completed. Check #{log_file_name} for details."
  end

  def initialize_stats
    {
      created: 0,
      updated: 0,
      errors: 0,
      skipped: 0
    }
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    Date.parse(date_string.to_s)
  rescue ArgumentError
    @logger.warn "Invalid date format: #{date_string}"
    nil
  end

  def safe_to_float(value)
    value&.to_f
  end

  def safe_to_integer(value)
    value&.to_i
  end

  def increment_stat(key)
    @stats[key] += 1
  end

  def log_record_error(record_id, error)
    @logger.error "Error processing record #{record_id}: #{error.message}"
    increment_stat(:errors)
  end

  private

  def setup_logger
    @log_file = File.open("log/#{log_file_name}", "a")
    Logger.new(@log_file)
  end

  def log_final_stats
    @logger.info "#{self.class.name} completed at #{Time.current}"
    @logger.info "Statistics: #{@stats}"

    Rails.logger.debug "Synchronization completed:"
    @stats.each { |key, value| puts "  #{key.to_s.humanize}: #{value}" }
  end
end
